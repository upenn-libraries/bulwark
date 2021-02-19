module StructuralMetadataSources
  extend ActiveSupport::Concern

  VALID_STRUCTURAL_METADATA_FIELDS = ['sequence', 'filename', 'label', 'viewing_direction', 'text_annotation'].freeze

  def structural_metadata(working_path)
    self.metadata_builder.repo.version_control_agent.get({ location: path }, working_path)

    # Save the path to CEPH and use that to retrieve the metadata instead
    # of needed to have the repository pulled down in order to complete a reindex.
    key = self.metadata_builder.repo.version_control_agent.look_up_key(path, working_path)
    self.remote_location = File.join(self.metadata_builder.repo.names.bucket, key)

    metadata_path = File.join(working_path, path)
    csv = File.open(metadata_path).read

    metadata = Bulwark::StructuredCSV.parse(csv)
    ordered_metadata = metadata.sort_by { |row| row['sequence'].to_i }

    self.original_mappings = { 'sequence' => ordered_metadata }

    self.user_defined_mappings = {
      'sequence' => ordered_metadata.map { |row| row.keep_if { |k, v| VALID_STRUCTURAL_METADATA_FIELDS.include?(k) } }
    }
  end

  def viewing_direction
    return nil unless source_type == 'structural'
    direction = user_defined_mappings['sequence'].map { |asset| asset['viewing_direction'] }.uniq
    raise 'Conflicting viewing_directions. Viewing direction must be the same for all assets' if direction.length > 1
    direction.first || 'left-to-right'
  end
end
