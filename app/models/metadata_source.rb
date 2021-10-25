require 'open-uri'

class MetadataSource < ActiveRecord::Base
  include DescriptiveMetadataSources
  include StructuralMetadataSources

  STRUCTURAL_TYPES = %w[custom structural_bibid pap_structural kaplan_structural pqc_ark pqc_combined_struct pqc_structural structural]
  DESCRIPTIVE_TYPES = %w[kaplan pap pqc_combined_desc pqc_desc voyager pqc descriptive]

  attr_accessor :xml_header, :xml_footer
  attr_accessor :user_defined_mappings

  belongs_to :metadata_builder, :foreign_key => 'metadata_builder_id'

  serialize :original_mappings, Hash
  serialize :user_defined_mappings, Hash
  serialize :children, Array

  def path
    read_attribute(:path) || ''
  end

  def num_objects
    read_attribute(:num_objects) || ''
  end

  def x_start
    read_attribute(:x_start) || ''
  end

  def y_start
    read_attribute(:y_start) || ''
  end

  def x_stop
    read_attribute(:x_stop) || ''
  end

  def y_stop
    read_attribute(:y_stop) || ''
  end

  def root_element
    read_attribute(:root_element) || ''
  end

  def parent_element
    read_attribute(:parent_element) || ''
  end

  def children
    read_attribute(:children) || ''
  end

  def original_mappings
    read_attribute(:original_mappings) || ''
  end

  def user_defined_mappings
    read_attribute(:user_defined_mappings) || ''
  end

  def source_type
    read_attribute(:source_type) || ''
  end

  def file_field
    read_attribute(:file_field) || ''
  end

  def view_type
    read_attribute(:view_type) || ''
  end

  def children=(children)
    self[:children] = children.reject(&:blank?)
  end

  def source_type=(source_type)
    self[:source_type] = source_type
    self[:user_defined_mappings] = nil
    self[:original_mappings] = nil
    self.update_last_used_settings
    self.metadata_builder.repo.update_steps(:metadata_source_type_specified) if self.metadata_builder.present?
  end

  def view_type=(view_type)
    self[:view_type] = view_type
    self.metadata_builder.repo.update_steps(:metadata_source_additional_info_set)
  end

  def original_mappings=(original_mappings)
    self[:original_mappings] = original_mappings
  end

  def user_defined_mappings=(user_defined_mappings)
    self[:user_defined_mappings] = user_defined_mappings
    self.metadata_builder.repo.update_steps(:metadata_mappings_generated) if user_defined_mappings.present?
  end

  def set_metadata_mappings(working_path = '')
    if self.source_type.present?
      case self.source_type
      when 'descriptive'
        descriptive_metadata(working_path)
      when 'structural'
        structural_metadata(working_path)
      end
    end

    self.metadata_builder.repo.update_steps(:metadata_extracted)
    self.save!
  end

  def update_last_used_settings
    self.last_settings_updated = DateTime.now
    self.save!
  end

  def thumbnail
    case self.source_type
      when 'custom'
        self.original_mappings['file_name'].present? ? self.original_mappings['file_name'].first : nil
      when 'structural_bibid', 'pap_structural', 'kaplan_structural', 'pqc_ark', 'pqc_combined_struct', 'pqc_combined_desc', 'pqc_structural'
        pages_with_files = []
        self.user_defined_mappings.select {|key, map| pages_with_files << map if map['file_name'].present?}
        pages_with_files.present? ? pages_with_files.sort_by.first {|p| p['serial_num']}['file_name'] : nil
    end
  end

  def filenames
    case self.source_type
    when 'custom'
      orig = ''
      self.original_mappings.each do |key, value|
        orig = value if key == self.file_field
      end
      return orig
    when 'structural_bibid', 'pap_structural', 'kaplan_structural', 'pqc_ark', 'pqc_combined_struct', 'pqc_combined_desc', 'pqc_structural'
      filenames = []
      self.user_defined_mappings.each do |key, value|
        filenames << value[self.file_field] if value[self.file_field].present?
      end
      return filenames
    when 'structural'
      self.user_defined_mappings['sequence'].map { |row| row['filename'] }
    else
      return nil
    end
  end
end
