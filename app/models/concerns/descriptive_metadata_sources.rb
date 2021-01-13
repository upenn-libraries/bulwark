module DescriptiveMetadataSources
  extend ActiveSupport::Concern

  # TODO: When PQC fields are finalized, move this list to the
  # Bulwark::PennQualifiedCore module.
  VALID_DESCRIPTIVE_METADATA_FIELDS = [
    'item_type', 'abstract', 'call_number', 'collection', 'contributor',
    'corporate_name', 'coverage', 'creator', 'date', 'description', 'format',
    'geographic_subject', 'identifier', 'includes', 'language', 'notes',
    'personal_name', 'provenance', 'publisher', 'relation', 'rights', 'source',
    'subject', 'title'
  ].freeze

  private

    # TODO: This should probably be within a transaction or the method that
    # calls it should be within a transaction.
    def descriptive_metadata(working_path)
      self.metadata_builder.repo.version_control_agent.get({ location: path }, working_path)

      # Save the path to CEPH and use that to retrieve the metadata instead
      # of needed to have the repository pulled down in order to reindex.
      key = self.metadata_builder.repo.version_control_agent.look_up_key(path, working_path)
      self.remote_location = File.join(self.metadata_builder.repo.names.bucket, key)

      # Parse the metadata in from a CSV. Assuming the first-non-header row contains the data.
      metadata_path = File.join(working_path, path)
      csv = File.open(metadata_path).read
      metadata = Bulwark::MultivaluedCSV.parse(csv)[0]

      raise StandardError, "No metadata present at #{metadata_path}" if metadata.empty?

      self.original_mappings = metadata

      if bibnumber = metadata['bibnumber']&.first
        # Pull metadata from Marmite.
        # Merge metadata provided with metadata from catalog. Metadata provided via CSV take precedent over catalog metadata.
        self.user_defined_mappings = catalog_metadata(bibnumber).merge(metadata)
      else
        # Remove any invalid column headers, TODO: maybe add a warning about an invalid column being used?

        # process data provided in hash. and save it to user_defined_mappings?
        self.user_defined_mappings = metadata.keep_if { |k, v| VALID_DESCRIPTIVE_METADATA_FIELDS.include?(k) }
      end
    end

    # Retrieves metadata from catalog through marmite and converts it to PQC.
    def catalog_metadata(bibnumber)
      marc_xml = MarmiteClient.marc21(bibnumber)
      Bulwark::PennQualifiedCore::TransformMarc.from_marc_xml(marc_xml)
    end
end
