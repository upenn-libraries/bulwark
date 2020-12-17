module StructuralMetadataSources
  extend ActiveSupport::Concern

  VALID_STRUCTURAL_METADATA_FIELDS = ['sequence', 'filename', 'label'].freeze

  def structural_metadata(working_path)
    self.metadata_builder.repo.version_control_agent.get({ location: path }, working_path)

    # Save the path to CEPH and use that to retrieve the metadata instead
    # of needed to have the repository pulled down in order to complete a reindex.
    key = self.metadata_builder.repo.version_control_agent.look_up_key(path, working_path)
    self.remote_location = File.join(self.metadata_builder.repo.names.bucket, key)

    metadata_path = File.join(working_path, path)
    csv = File.open(metadata_path).read

    metadata = CSV.parse(csv, headers: true).map(&:to_h)
    ordered_metadata = metadata.sort_by { |row| row['sequence'].to_i }

    self.original_mappings = { 'sequence' => ordered_metadata }

    self.user_defined_mappings = {
      'sequence' => ordered_metadata.map { |row| row.keep_if { |k, v| VALID_STRUCTURAL_METADATA_FIELDS.include?(k) } }
    }
  end
end
