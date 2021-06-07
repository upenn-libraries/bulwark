# frozen_string_literal: true

module StructuralMetadataSources
  extend ActiveSupport::Concern

  VALID_STRUCTURAL_METADATA_FIELDS = ['sequence', 'filename', 'label', 'viewing_direction', 'table_of_contents', 'display'].freeze

  PAGED = 'paged'
  INDIVIDUALS = 'individuals'
  VIEWING_HINTS = [PAGED, INDIVIDUALS].freeze

  RIGHT_TO_LEFT = 'right-to-left'
  LEFT_TO_RIGHT = 'left-to-right'
  TOP_TO_BOTTOM = 'top-to-bottom'
  BOTTOM_TO_TOP = 'bottom-to-top'
  VIEWING_DIRECTIONS = [LEFT_TO_RIGHT, RIGHT_TO_LEFT, TOP_TO_BOTTOM, BOTTOM_TO_TOP].freeze

  def structural_metadata(working_path)
    self.metadata_builder.repo.version_control_agent.get({ location: path }, working_path)

    # Save the path to CEPH and use that to retrieve the metadata instead
    # of needed to have the repository pulled down in order to complete a reindex.
    key = self.metadata_builder.repo.version_control_agent.look_up_key(path, working_path)
    self.remote_location = File.join(self.metadata_builder.repo.names.bucket, key)

    metadata_path = File.join(working_path, path)
    csv = File.open(metadata_path).read

    metadata = Bulwark::StructuredCSV.parse(csv).map { |m| m.delete_if { |_, v| v.blank? } } # Removing blank values
    ordered_metadata = metadata.sort_by { |row| row['sequence'].to_i }

    self.original_mappings = { 'sequence' => ordered_metadata }

    self.user_defined_mappings = {
      'sequence' => ordered_metadata.map { |row| row.keep_if { |k, _v| VALID_STRUCTURAL_METADATA_FIELDS.include?(k) } }
    }
  end

  def viewing_direction
    return nil unless source_type == 'structural'
    direction = user_defined_mappings['sequence'].map { |asset| asset['viewing_direction'] }.uniq
    raise 'Conflicting viewing_directions. Viewing direction must be the same for all assets' if direction.length > 1
    direction.first || LEFT_TO_RIGHT
  end

  def viewing_hint
    return nil unless source_type == 'structural'
    display = user_defined_mappings['sequence'].map { |asset| asset['display'] }.uniq
    raise 'Conflicting viewing hint. Viewing hint must be the same for all assets' if display.length > 1
    display.first || INDIVIDUALS
  end
end
