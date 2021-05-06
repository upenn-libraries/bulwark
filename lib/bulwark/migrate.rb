# frozen_string_literal: true
require 'jhove_service'

module Bulwark
  class Migrate
    ACTION = 'migrate'

    attr_reader :unique_identifier, :action, :migrated_by, :descriptive_metadata,
                :structural_metadata, :errors

    # Initializes object to migrate digital objects.
    #
    # @param [Hash] arguments passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :migrated_by
    # @options opts [String] :unique_identifier
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [Hash] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      @action               = args[:action]&.downcase
      @unique_identifier    = args[:unique_identifier]
      @migrated_by          = args[:migrated_by]
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata  = args[:structural].blank? ? nil : Import::StructuralMetadataGenerator.new(args[:structural])
      @errors               = []
    end

    # Validates that digital object can be migrated. These checks are meant to be
    # lightweight checks that can be done before pulling down the entire repository.
    # Returns false if unable to migrate object. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @ return [False] if errors were generated
    def validate
      # Check that action is correct
      @errors << "\"#{action}\" is not a valid migration action" unless ACTION == action

      # Check that migrated_by is present.
      @errors << "Missing migrated_by" if migrated_by.blank?

      # Check that structural and descriptive metadata is present
      @errors << "Missing structural metadata" if structural_metadata.blank?
      @errors << "Missing metadata" if descriptive_metadata.blank?

      # Check that unique_identifier is present.
      @errors << "Missing unique_identifier" if unique_identifier.blank?

      # Check that repo can be retrieved.
      if unique_identifier.present?
        if repo
          # Check that items have been "ingested"
          @errors << "Repo has not been ingested" unless repo.ingested

          # Check for solr record
          @errors << "Solr document for this object is not present" unless solr_document_present?

          # Check that there are only two metadata sources, one kaplan and one structural_kaplan (eventually extend this)
          metadata_sources = repo.metadata_builder.metadata_source.map(&:source_type)
          @errors << "Repo has more than two metadata sources" if metadata_sources.count > 2

          # Check that a User record for owner can be found.
          owner = User.find_by(email: repo.owner)
          @errors << "Cannot retrieve User record for owner" if owner.nil?

          # Check that metadata subdirectory is data/metadata
          @errors << "Metadata subdirectory is not 'data/metadata'" if repo.metadata_subdirectory != 'data/metadata'
        else
          @errors << "Repo could not be found"
        end
      end

      @errors.concat(structural_metadata.errors) if structural_metadata && !structural_metadata.valid?

      errors.empty?
    end

    # Processing migration of objects from old format to new format.
    def process
      validate # Validate before processing data.

      ## Manually validate path and drive for structural.
      if structural_metadata
        @errors << "structural path invalid" if structural_metadata.drive && structural_metadata.path && !MountedDrives.valid_path?(structural_metadata.drive, structural_metadata.path)
      end

      return Bulwark::Import::Result.new(status: DigitalObjectImport::FAILED, errors: errors) unless @errors.empty?

      # -- Additional validations that require the git repo to be present. --

      # Get all filenames in assets directory.
      glob_path = File.join(repo.clone_location, repo.assets_subdirectory, "*")
      asset_filenames = Dir.glob(glob_path).map { |f| File.basename(f) } # Filenames only.

      # Check that all files have valid extensions
      extensions = asset_filenames.map { |f| File.extname(f).gsub(/^\./, '') }.uniq
      invalid_extensions = extensions - valid_file_extensions
      @errors << "Assets in git repo contain invalid file extensions: #{invalid_extensions.join(', ')}" unless invalid_extensions.blank?

      # Check that there aren't files with the same name but different extension
      without_extension = asset_filenames.map { |f| File.basename(f, '.*') }
      @errors << "There are assets that share the same name but different extension" if without_extension.any? { |f| without_extension.count(f) > 1 }

      return Bulwark::Import::Result.new(status: DigitalObjectImport::FAILED, errors: errors) if @errors.any?

      # -- Cleanup before migration --

      # Remove all metadata sources and endpoints
      repo.metadata_builder.metadata_source.destroy_all
      repo.endpoint.destroy_all

      # Delete all files in the derivative and metadata directories
      remove_directory(repo.metadata_subdirectory, "Removing all metadata files as part of migration")
      remove_directory(repo.derivatives_subdirectory, "Removing all derivative files as part of migration")

      # Update published_at, created_by and updated by
      repo.update!(
        first_published_at: repo.created_at,
        created_by: User.find_by(email: repo.owner),
        updated_by: migrated_by
      )

      # -- Migration --

      # Characterize Files
      repo.characterize_assets

      # Create Asset Records
      repo.create_or_update_assets

      # Generate derivatives
      repo.generate_derivatives

      # Add metadata source for descriptive
      repo.merge_descriptive_metadata(descriptive_metadata.deep_stringify_keys)

      # Add metadata source for structural
      new_structural = structural_metadata.csv
      repo.add_structural_metadata(new_structural)

      # Validate structural metadata
      repo.validate_structural_metadata!

      # Recreate preservation.xml and mets.xml
      repo.add_preservation_and_mets_xml

      # Remove clone
      repo.delete_clone

      # Make sure thumbnail is set and make sure current thumbnail is valid
      if repo.thumbnail.blank? || !repo.assets.map(&:filename).include?(repo.thumbnail)
        thumbnail = repo.structural_metadata.user_defined_mappings['sequence'].sort_by { |file| file['sequence'] }.first['filename']
        repo.update!(thumbnail: thumbnail)
      end

      # Cleanup models. Need to clean up models before IIIF manifest is generated.
      repo.update!(file_display_attributes: nil, images_to_render: nil, new_format: true)
      repo.metadata_builder.update(xml_preview: nil, preserve: nil)

      # Regenerate IIIF manifest
      repo.create_iiif_manifest if Bulwark::Config.bulk_import[:create_iiif_manifest]

      # Publish
      repo.publish

      Bulwark::Import::Result.new(status: DigitalObjectImport::SUCCESSFUL, repo: repo)
    rescue => e
      Honeybadger.notify(e) # Sending full error to Honeybadger.
      Bulwark::Import::Result.new(status: DigitalObjectImport::FAILED, errors: [e.message], repo: repo)
    end

    private

      def repo
        @repo ||= Repo.find_by(unique_identifier: unique_identifier, new_format: false)
      end

      def solr_document_present?
        Blacklight.default_index.search(q: "id:#{repo.names.fedora}", fl: 'id').docs.count == 1
      end

      def valid_file_extensions
        Bulwark::Config.digital_object[:file_extensions]
      end

      def remove_directory(path, message)
        # Skip if there aren't any files to delete.
        absolute_path = File.join(repo.clone_location, path)
        return if Dir.entries(absolute_path).delete_if { |entry| ['.', '..', '.keep'].include?(entry) }.blank?

        git = ExtendedGit.open(repo.clone_location)
        git.remove(["#{path}/*", ':(exclude)*/.keep'], recursive: true)
        git.commit(message)
        git.push('origin', 'master')
        git.push('origin', 'git-annex')
        git.annex.sync(content: true)
      end
  end
end
