# frozen_string_literal: true

module Bulwark
  class Import
    CREATE = 'create'
    UPDATE = 'update'
    IMPORT_ACTIONS = [CREATE, UPDATE].freeze

    attr_reader :unique_identifier, :action, :directive_name, :created_by, :assets,
                :descriptive_metadata, :structural_metadata, :derivatives,
                :repo, :errors

    # Initializes object to import digital objects.
    #
    # @param [Hash] args passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :created_by
    # @options opts [String] :directive_name
    # @options opts [String] :unique_identifier
    # @options opts [FileLocations] :assets
    # @options opts [Hash<String,FileLocations>] :derivatives
    # @options opts [TrueClass, FalseClass] :publish
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [StructuralMetadataGenerator] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      @action               = args[:action]&.downcase
      @unique_identifier    = args[:unique_identifier]
      @directive_name       = args[:directive_name]
      @created_by           = args[:created_by]
      @publish              = args.fetch(:publish, 'false').casecmp('true').zero?
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata  = args[:structural].blank? ? nil : StructuralMetadataGenerator.new(args[:structural])
      @assets               = args[:assets].blank? ? nil : FileLocations.new(args[:assets])
      @derivatives          = derivatives_options(args[:derivatives])
      @errors               = []
    end

    # Validates that digital object can be created or updated with all the information
    # given. These checks are meant to be lightweight checks that can be done
    # before pulling down the entire repository. Returns false if there is
    # missing or incorrect information. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @return [False] if errors were generated
    def validate
      @errors << "\"#{action}\" is not a valid import action" unless IMPORT_ACTIONS.include?(action)

      if action == CREATE
        @errors << "\"directive_name\" must be provided to create an object" unless directive_name
        @errors << "structural must be provided to create an object" unless structural_metadata
        @errors << "assets must be provided to create an object" unless assets
        @errors << "metadata must be provided to create an object" if descriptive_metadata.blank?
        if unique_identifier
          @errors << "\"#{unique_identifier}\" already belongs to an object. Cannot create new object with given unique identifier." if Repo.find_by(unique_identifier: unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" if unique_identifier && !Utilities.ark_exists?(unique_identifier)
        end
      end

      if action == UPDATE
        if unique_identifier
          @repo = Repo.find_by(unique_identifier: unique_identifier, new_format: true)
          @errors << "\"unique_identifier\" does not belong to an object. Cannot update object." unless repo
        else
          @errors << "\"unique_identifier\" must be provided when updating an object"
        end
      end

      @errors.concat(assets.errors.map { |e| "assets #{e}" }) if assets && !assets.valid?
      @errors.concat(derivatives[:access].errors.map { |e| "derivative.access #{e}" }) if derivatives && derivatives[:access].valid?

      if structural_metadata && !structural_metadata.valid?
        @errors.concat structural_metadata.errors
        # @errors << "structural path invalid" if structural_metadata[:drive] && structural_metadata[:path] && !MountedDrives.valid_path?(structural_metadata[:drive], structural_metadata[:path])
      end

      @errors << "created_by must always be provided" unless created_by
      errors.empty?
    end

    def process
      validate # Validate before processing data.

      # Running filepath validations here, until we can configure our web containers to be able to do these checks.
      @errors << "asset path invalid" if assets && !assets.valid_paths?

      if structural_metadata
        # If structural metadata provided by CSV, check that file is present.
        @errors << "structural path invalid" if structural_metadata.drive && structural_metadata.path && !MountedDrives.valid_path?(structural_metadata.drive, structural_metadata.path)

        # Check that files in structural metadata are valid
        assets_present = []
        assets_present.concat assets.files_available if assets
        assets_present.concat repo.assets.map(&:filename) if repo

        files_not_present = structural_metadata.all_filenames - assets_present
        @errors << "Structural metadata contains the following invalid filenames: #{files_not_present.join(', ')}" unless files_not_present.blank?
      end

      if derivatives && derivatives[:access]
        if !derivatives[:access].valid_paths? # Ensure derivative filepaths are valid.
          @errors << "derivatives access path invalid"
        else # If derivative filepaths are valid do other checks
          # Ensure derivatives have original/preservation files
          derivative_basenames = derivatives[:access].files_available.map { |f| File.basename(f, '.*') }

          assets_present = []
          assets_present.concat assets.files_available if assets
          assets_present.concat repo.assets.map(&:filename) if repo

          assets_basenames = assets_present.map { |f| File.basename(f, '.*') }

          invalid_derivatives = derivative_basenames - assets_basenames

          @errors << "Invalid derivatives: #{invalid_derivatives.join(', ')}" unless invalid_derivatives.blank?

          # TODO: Ensure derivatives have valid extension
          derivative_extensions = derivatives[:access].files_available.map { |f| File.extname(f)[1..-1] }.uniq
          invalid_extensions = derivative_extensions - DigitalObject::Derivatives::DERIVATIVE_EXTENSIONS.values

          @errors << "Derivatives with invalid file extensions: #{invalid_extensions.join(', ')}" unless invalid_extensions.blank?
        end
      end

      return error_result(@errors) unless @errors.empty?

      # Create repo if action is create
      @repo = create_digital_object if action == CREATE

      update_digital_object(repo)

      # Add assets to repository.
      repo.add_assets(assets.absolute_paths) if assets

      # Add descriptive metadata
      unless descriptive_metadata.empty?
        repo.merge_descriptive_metadata(descriptive_metadata.deep_stringify_keys)
      end

      # Add structural metadata. Replace structural metadata if its already present.
      # FIXME: This isn't a great solution because there is a potential for
      # data loss if more detailed structural metadata is already available.
      if structural_metadata
        new_structural = structural_metadata.csv
        repo.add_structural_metadata(new_structural)

        # Check that all filenames referenced in the structural metadata are valid.
        repo.validate_structural_metadata!
      end

      # Copy and link derivatives if they are provided externally.
      repo.copy_and_link_derivatives('access', derivatives[:access].absolute_paths) if derivatives&.dig(:access)

      # Derivative generation (only if an asset location has been provided)
      repo.generate_derivatives if assets

      # Create Thumbnail
      thumbnail = repo.structural_metadata.user_defined_mappings['sequence'].sort_by { |file| file['sequence'] }.first['filename']
      repo.update!(thumbnail: thumbnail)

      # Generate xml: generate mets.xml and preservation.xml (can be moved to earlier in the process)
      repo.add_preservation_and_mets_xml

      # Remove clone
      repo.delete_clone

      # Create Marmite IIIF Manifest
      repo.create_iiif_manifest if Settings.bulk_import.create_iiif_manifest

      # Publish if publish flag is set to true.
      if @publish
        unless repo.publish
          @errors << 'Problem when attempting to publish the Digital Object.'
          return error_result @errors, repo
        end
      end

      Result.new(status: DigitalObjectImport::SUCCESSFUL, repo: repo)
    rescue => e
      Honeybadger.notify(e) # Sending full error to Honeybadger.
      repo.delete_clone if repo&.cloned? # Delete cloned repo if there is one present
      error_result [e.message], repo
    end

    private

      def derivatives_options(derivatives)
        return if derivatives.blank? || derivatives[:access].blank?
        { access: FileLocations.new(derivatives[:access]) }
      end

      # @param [Array] errors
      # @param [Repo, nil] repository
      def error_result(errors, repository = nil)
        Result.new(status: DigitalObjectImport::FAILED, errors: errors, repo: repository)
      end

      def create_digital_object
        repo = Repo.new(
          human_readable_name: directive_name,
          metadata_subdirectory: 'metadata',
          assets_subdirectory: 'assets',
          file_extensions: Settings.digital_object.file_extensions,
          metadata_source_extensions: ['csv'],
          preservation_filename: 'preservation.xml',
          new_format: true, # Setting to differentiate from previously created repos
          created_by: created_by
        )
        repo.unique_identifier = unique_identifier if unique_identifier
        repo.save!
        repo
      end

      def update_digital_object(repo)
        repo.update!(
          description: 'Generated from CSV through bulk import',
          last_external_update: Time.current,
          updated_by: created_by
        )
      end
  end
end
