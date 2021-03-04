module Bulwark
  class Migrate
    attr_reader :unique_identifier, :action, :updated_by, :descriptive_metadata,
                :structural_metadata, :repo, :errors

    # Initializes object to migrate digital objects.
    #
    # @param [Hash] arguments passed in to create/update digital objects
    # @options opts [String] :action
    # @options opts [User] :updated_by
    # @options opts [String] :unique_identifier
    # @options opts [Hash] :metadata  # gets mapped to descriptive_metadata
    # @options opts [Hash] :structural  # gets mapped to structural_metadata
    def initialize(args)
      args = args.deep_symbolize_keys

      @action = args[:action]&.downcase
      @unique_identifier = args[:unique_identifier]
      @updated_by = args[:updated_by]
      @descriptive_metadata = args.fetch(:metadata, {})
      @structural_metadata = args.fetch(:structural, {})
      @errors = []
    end

    # Validates that digital object can be migrated. These checks are meant to be
    # lightweight checks that can be done before pulling down the entire repository.
    # Returns false if unable to migrate object. Errors are stored in an instance variable.
    #
    # @return [True] if no errors were generated
    # @ return [False] if errors were generated
    def validate
      # Check that repo can be retrieved.
      repo = Repo.find_by(unique_identifier: unique_identifier, new_format: false)
      @errors << "repo could not be found" && return unless repo

      # Check that items have been "ingested" and have a solr record
      @errors << "Repo has not been ingested; Cannot migrate." unless repo.ingest
      # TODO: check for solr record

      # Check that structural and descriptive metadata is present
      @errors << "structural metadata is required" if structural_metadata.blank?
      @errors << "metadata is required" if descriptive_metadata.blank?

      # Check that there are only two metadata sources, one kaplan and one structural_kaplan (eventually extend this)
      metadata_sources = repo.metadata_builder.metadata_source.map(&:source_type)
      @errors << "Repo has more than two metadata sources; Cannot migrate." if metadata_sources.count > 2
      @errors << "Metadata sources does not include kaplan" unless metadata_sources.include?('kaplan')
      @errors << "Metadata sources does not include kaplan_structural" unless metadata_sources.include?('kaplan_structural')

      # Check that a User record for owner can be found.
      owner = User.find_by(email: repo.owner)
      @errors << "Cannot retrieve User record for owner" if owner.nil?
    end


    def process
      validate # Validate before processing data.

      return Result.new(status: DigitalObjectImport::FAILED, errors: errors) unless @errors.empty?

      # Retrieve Repo
      @repo = Repo.find_by(unique_identifier: unique_identifier, new_format: false)

      # -- Additional validations that require the git repo to be present. --
      #
      # TODO: Check that all assets have supported extensions
      # TODO: Check that there aren't files with the same name but different extension

      return Result.new(status: DigitalObjectImport::FAILED, errors: errors) unless @errors.empty?

      # -- Cleanup before migration --

      # Remove all metadata sources and endpoints
      repo.metadata_builder.metadata_source.destroy_all!
      repo.endpoint.destroy_all!

      # TODO: Delete all files in the derivative and metadata directories

      # Update published_at, created_by and updated by
      repo.update!(
        first_published_at: repo.created_at,
        created_by: User.find_by(email: repo.owner),
        updated_by: updated_by
      )


      # -- Migration --
      # TODO: characterize files
      # TODO: create asset records
      #
      # Generate derivatives
      repo.generate_derivatives

      # Add metadata source for descriptive
      repo.merge_descriptive_metadata(descriptive_metadata.deep_stringify_keys)

      # TODO: add metadata source for structural

      # Recreate preservation.xml and mets.xml
      repo.add_preservation_and_mets_xml

      # Regenerate IIIF manifest
      repo.create_iiif_manifest if Bulwark::Config.bulk_import[:create_iiif_manifest]

      # Make sure thumbnail is set
      unless repo.thumbnail
        thumbnail = repo.structural_metadata.user_defined_mappings['sequence'].sort_by { |file| file['sequence'] }.first['filename']
        repo.update!(thumbnail: thumbnail)
      end

      # Publish
      repo.publish


      # -- Post migration processing --

      # Cleanup models
      repo.update!(file_display_attributes: nil, images_to_render: nil, new_format: true)
      repo.metadata_builder.update(xml_preview: nil, preserve: nil)

    rescue => e
      Honeybadger.notify(e) # Sending full error to Honeybadger.
      Result.new(status: DigitalObjectImport::FAILED, errors: [e.message], repo: repo)
    end
  end
end
