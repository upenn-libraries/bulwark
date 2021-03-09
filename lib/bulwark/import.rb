# frozen_string_literal: true
require 'jhove_service'

module Bulwark
  class Import
    CREATE = 'create'
    UPDATE = 'update'
    IMPORT_ACTIONS = [CREATE, UPDATE].freeze

    attr_reader :unique_identifier, :action, :directive_name, :created_by, :assets,
                :descriptive_metadata, :structural_metadata,
                :repo, :errors

    # Initializes object to import digital objects.
    #
    # @param [Hash] arguments passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :created_by
    # @options opts [String] :directive_name
    # @options opts [String] :unique_identifier
    # @options opts [Hash] :assets
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [Hash] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      @action = args[:action]&.downcase
      @unique_identifier = args[:unique_identifier]
      @directive_name = args[:directive_name]
      @created_by = args[:created_by]
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata = args.fetch(:structural, {})
      @assets = args.fetch(:assets, {})
      @errors = []
    end

    # Validates that digital object can be created or updated with all the information
    # given. These checks are meant to be lightweight checks that can be done
    # before pulling down the entire repository. Returns false if there is
    # missing or incorrect information. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @ return [False] if errors were generated
    def validate
      @errors << "\"#{action}\" is not a valid import action" unless IMPORT_ACTIONS.include?(action)

      if action == CREATE
        @errors << "\"directive_name\" must be provided to create an object" unless directive_name
        @errors << "structural must be provided to create an object" unless structural_metadata && (structural_metadata[:filenames] || (structural_metadata[:drive] && structural_metadata[:path]))
        @errors << "\"assets.path\" and \"assets.drive\" must be provided to create an object" if assets && (!assets[:drive] || !assets[:path])
        @errors << "metadata must be provided to create an object" if descriptive_metadata.blank?
        if unique_identifier
          @errors << "\"#{unique_identifier}\" already belongs to an object. Cannot create new object with given unique identifier." if Repo.find_by(unique_identifier: unique_identifier)
          @errors << "\"#{unique_identifier}\" is not minted" if unique_identifier && !Utilities.ark_exists?(unique_identifier)
        end
      end

      if action == UPDATE
        @errors << "\"unique_identifier\" must be provided when updating an object" unless unique_identifier
        @errors << "\"unique_identifier\" does not belong to an object. Cannot update object." if unique_identifier && !Repo.find_by(unique_identifier: unique_identifier)
      end

      if assets
        @errors << "assets drive invalid" if assets[:drive] && !MountedDrives.valid?(assets[:drive])
        # @errors << "asset path invalid" if assets[:drive] && assets[:path] && !MountedDrives.valid_path?(assets[:drive], assets[:path])
      end

      if structural_metadata
        @errors << "cannot provide structural metadata two different ways" if (structural_metadata[:drive] || structural_metadata[:path]) && structural_metadata[:filenames]
        @errors << "structural drive invalid" if structural_metadata[:drive] && !MountedDrives.valid?(structural_metadata[:drive])
        # @errors << "structural path invalid" if structural_metadata[:drive] && structural_metadata[:path] && !MountedDrives.valid_path?(structural_metadata[:drive], structural_metadata[:path])
      end

      @errors << "created_by must always be provided" unless created_by
      errors.empty?
    end

    def process
      validate # Validate before processing data.

      # Running filepath validations here, until we can configure our web containers to be able to do these checks.
      if assets
        @errors << "asset path invalid" if assets[:drive] && assets[:path] && !MountedDrives.valid_path?(assets[:drive], assets[:path])
      end

      if structural_metadata
        @errors << "structural path invalid" if structural_metadata[:drive] && structural_metadata[:path] && !MountedDrives.valid_path?(structural_metadata[:drive], structural_metadata[:path])
      end

      return Result.new(status: DigitalObjectImport::FAILED, errors: errors) unless @errors.empty?

      # Retrieve or create repo.
      @repo = case action.downcase
              when CREATE
                create_digital_object
              when UPDATE
                Repo.find_by(unique_identifier: unique_identifier, new_format: true)
              end

      update_digital_object(repo)

      # Add assets to repository.
      unless assets.empty?
        assets_path = File.join(MountedDrives.path_to(assets[:drive]), assets[:path])
        repo.add_assets(assets_path)
      end

      # Add descriptive metadata
      unless descriptive_metadata.empty?
        repo.merge_descriptive_metadata(descriptive_metadata.deep_stringify_keys)
      end

      # Add structural metadata. Replace structural metadata if its already present.
      # FIXME: This isn't a great solution because there is a potential for
      # data loss if more detailed structural metadata is already available.
      new_structural = Bulwark::Import::Utilities.structural_metadata_csv(structural_metadata)
      repo.add_structural_metadata(new_structural) if new_structural

      # Check that all filenames referenced in the structural metadata are valid.
      repo.validate_structural_metadata!

      # Derivative generation (only if an asset location has been provided)
      repo.generate_derivatives unless assets.empty?

      # Create Thumbnail
      thumbnail = repo.structural_metadata.user_defined_mappings['sequence'].sort_by { |file| file['sequence'] }.first['filename']
      repo.update!(thumbnail: thumbnail)

      # Generate xml: generate mets.xml and preservation.xml (can be moved to earlier in the process)
      repo.add_preservation_and_mets_xml

      # Remove clone
      repo.delete_clone

      # Create Marmite IIIF Manifest
      repo.create_iiif_manifest if Bulwark::Config.bulk_import[:create_iiif_manifest]

      # TODO: Publish if publish flag is set to true.

      Result.new(status: DigitalObjectImport::SUCCESSFUL, repo: repo)
    rescue => e
      Honeybadger.notify(e) # Sending full error to Honeybadger.
      Result.new(status: DigitalObjectImport::FAILED, errors: [e.message], repo: repo)
    end

    private

      def create_digital_object
        repo = Repo.new(
          human_readable_name: directive_name,
          metadata_subdirectory: 'metadata',
          assets_subdirectory: 'assets',
          file_extensions: ['tif', 'TIF', 'tiff', 'jpeg', 'jpg', 'pdf'],
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
