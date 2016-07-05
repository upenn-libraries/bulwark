require "open-uri"

class MetadataSource < ActiveRecord::Base

  attr_accessor :xml_header, :xml_footer
  attr_accessor :user_defined_mappings

  belongs_to :metadata_builder, :foreign_key => "metadata_builder_id"

  include Utils
  include CustomEncodings

  validates :user_defined_mappings, :xml_tags => true

  serialize :original_mappings, Hash
  serialize :user_defined_mappings, Hash
  serialize :children, Array

  $xml_header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>"
  $xml_footer = "</root>"

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

  def children=(children)
    self[:children] = children.reject(&:empty?)
  end

  def user_defined_mappings=(user_defined_mappings)
    self[:user_defined_mappings] = user_defined_mappings
  end

  def set_metadata_mappings
    fresh_clone = false
    unless File.exist?(self.metadata_builder.repo.version_control_agent.working_path)
      self.metadata_builder.repo.version_control_agent.clone
      fresh_clone = true
    end
    if self.source_type.present?
      case self.source_type
      when "custom"
        self.original_mappings = _convert_metadata
      when "voyager"
        self.user_defined_mappings = _set_voyager_data
      end
    end
    self.metadata_builder.repo.version_control_agent.delete_clone if fresh_clone
    self.save!
  end

  def build_xml
    self.set_metadata_mappings
    self.metadata_builder.repo.version_control_agent.clone
    self.generate_and_build_xml
    self.children.each do |child|
      source = MetadataSource.find(child)
      source.set_metadata_mappings
      source.generate_and_build_xml
    end
    self.generate_parent_child_xml
    self.metadata_builder.repo.version_control_agent.delete_clone
  end

  def generate_and_build_xml(fname = self.path)
    xml_fname = "#{fname}.xml"
    case self.source_type
    when "custom"
      @xml_content_final_copy = xml_from_custom(fname)
    when "voyager"
      @xml_content_final_copy = xml_from_voyager
    end
    _build_preservation_xml(xml_fname, @xml_content_final_copy)
    self.metadata_builder.save!
    self.metadata_builder.repo.version_control_agent.commit("Generated preservation XML for #{fname}")
    self.metadata_builder.repo.version_control_agent.push
  end

  def xml_from_voyager
    @xml_content = ""
    self.user_defined_mappings.each do |mapping|
      tag = mapping.first
      mapping.last.each do |m|
        @xml_content << "<#{tag}>#{m}</#{tag}>"
      end
    end
    @xml_content
  end

  def xml_from_custom(fname)
    @xml_content = ""
    unless self.children.empty?
      self.user_defined_mappings.each do |mapping|
        tag = mapping.last["mapped_value"]
        self.original_mappings[mapping.first].each do |field_value|
          @xml_content << "<#{tag}>#{field_value}</#{tag}>"
        end
      end
    else
      self.metadata_builder.repo.version_control_agent.get(:get_location => fname)
      @xml_content << _child_values(fname)
    end
    if self.root_element.present?
      @xml_content_transformed = "<#{root_element}>#{@xml_content}</#{root_element}>"
    else
      @xml_content_transformed = "#{@xml_content}"
    end
    @xml_content_transformed
  end

  def generate_parent_child_xml
    self.children.each do |child|
      metadata_path = "#{self.metadata_builder.repo.version_control_agent.working_path}/#{self.metadata_builder.repo.metadata_subdirectory}"
      child_path = MetadataSource.where(:id => child).pluck(:path).first
      key_xml_path = "#{self.path}.xml"
      child_xml_path = "#{child_path}.xml"
      self.metadata_builder.repo.version_control_agent.get(:get_location => key_xml_path)
      self.metadata_builder.repo.version_control_agent.get(:get_location => child_xml_path)
      xml_content = File.open(key_xml_path, "r"){|io| io.read}
      child_xml_content = File.open(child_xml_path, "r"){|io| io.read}
      _strip_headers(xml_content) && _strip_headers(child_xml_content)
      end_tag = "</#{self.root_element}>"
      insert_index = xml_content.index(end_tag)
      xml_content.insert(insert_index, child_xml_content)
      xml_unified_filename = "#{self.metadata_builder.repo.version_control_agent.working_path}/#{self.metadata_builder.repo.metadata_subdirectory}/#{self.metadata_builder.repo.preservation_filename}"
      self.metadata_builder.repo.version_control_agent.unlock(xml_unified_filename) if File.exists?(xml_unified_filename)
      _build_preservation_xml(xml_unified_filename,xml_content)
      self.metadata_builder.repo.version_control_agent.commit("Generated unified XML for #{self.path} and #{child_path} at #{xml_unified_filename}")
      self.metadata_builder.repo.version_control_agent.push
      self.metadata_builder.save!
    end
  end

  def generate_review_status_xml
    review_status_xml = ""
    self.metadata_builder.repo.review_status.each do |review_status|
      review_status_xml << "<review_status>#{review_status}</review_status>"
    end
    return review_status_xml
  end

  def parse_error_messages(error_messages)
    parsed = "<ul>"
    error_messages.flatten.each do |message|
      parsed << "<li>#{message}</li>"
    end
    parsed << "</ul>"
    return parsed
  end

  private

    def _set_voyager_data
      _refresh_bibid
      spreadsheet_values = {}
      voyager_source = open("http://dla.library.upenn.edu/dla/franklin/lookup/#{self.original_mappings["bibid"]}.xml")
      data = Nokogiri::XML(voyager_source)
      data.children.children.children.children.children.each do |child|
        if child.name == "datafield"
          header = CustomEncodings::Marc21::Constants::TAG.include?(child.attributes["tag"].value) ?  CustomEncodings::Marc21::Constants::TAG[child.attributes["tag"].value] : nil
          child_value = []
          child.children.each do |c|
            child_value << c.text
          end
          if header.present?
            spreadsheet_values["#{header}"] = child_value
          end
        end
      end
      return spreadsheet_values
    end

    # def _build_spreadsheet_derivative(spreadsheet_values, options = {})
    #   spreadsheet_derivative_path = "#{self.metadata_builder.repo.version_control_agent.working_path}/#{Utils.config.object_derivatives_path}/#{self.original_mappings["bibid"]}.xlsx"
    #   self.metadata_builder.metadata_source << MetadataSource.create(path: spreadsheet_derivative_path, source_type: "voyager_derivative", view_type: options[:view_type], x_start: options[:x_start], y_start: options[:y_start], x_stop: options[:x_stop], y_stop: options[:y_stop]) unless self.metadata_builder.metadata_source.where(metadata_builder_id: self.metadata_builder.id).pluck(:path) == spreadsheet_derivative_path
    #   self.metadata_builder.save!
    #   workbook = RubyXL::Workbook.new
    #   worksheet = workbook[0]
    #   spreadsheet_values.keys.each_with_index do |key, k_index|
    #     worksheet.add_cell(0, k_index, key)
    #     spreadsheet_values[key].each_with_index do |val, v_index|
    #       worksheet.add_cell(v_index+1,k_index,val)
    #     end
    #   end
    #   workbook.write(spreadsheet_derivative_path)
    #   self.metadata_builder.repo.version_control_agent.commit("Created derivative spreadsheet of Voyager metadata")
    #   self.metadata_builder.repo.version_control_agent.push
    #   generate_and_build_xml("#{self.metadata_builder.repo.version_control_agent.working_path}/#{Utils.config.object_derivatives_path}/#{self.original_mappings["bibid"]}.xlsx")
    # end

    def _refresh_bibid
      self.metadata_builder.repo.version_control_agent.get(:get_location => "#{self.path}")
      worksheet = RubyXL::Parser.parse(self.path)
      self.original_mappings = {"bibid" => worksheet[0][1][0].value}
    end

    def _convert_metadata
      begin
        pathname = Pathname.new(self.path)
        ext = pathname.extname.to_s[1..-1]
        case ext
        when "xlsx"
          self.metadata_builder.repo.version_control_agent.get(:get_location => "#{self.path}")
          @mappings = _generate_mapping_options_xlsx
        else
          raise "Illegal metadata source unit type"
        end
        return @mappings
      rescue
        raise $!, "Metadata conversion failed due to the following error(s): #{$!}", $!.backtrace
      end
    end

    def _generate_mapping_options_xlsx
      mappings = {}
      headers = []
      iterator = 0
      x_start, y_start, x_stop, y_stop = _offset
      workbook = RubyXL::Parser.parse(self.path)
      case self.view_type
      when "horizontal"
        while((x_stop >= (x_start+iterator)) && (workbook[0][y_start].present?) && (workbook[0][y_start][x_start+iterator].present?))
          header = workbook[0][y_start][x_start+iterator].value
          headers << header
          vals = []
          #This variable could be user-defined in order to let the user set the values _offset
          vals_iterator = 1
          while(workbook[0][y_start+vals_iterator].present? && workbook[0][y_start+vals_iterator][x_start+iterator].present?) do
            vals << workbook[0][y_start+vals_iterator][x_start+iterator].value
            vals_iterator += 1
          end
          mappings[header] = vals
          iterator += 1
        end
      when "vertical"
        while((y_stop >= (y_start+iterator)) && (workbook[0][y_start+iterator].present?) && (workbook[0][y_start+iterator][x_start].present?))
          header = workbook[0][y_start+iterator][x_start].value
          headers << header
          vals = []
          vals_iterator = 1
          while(workbook[0][y_start+iterator].present? && workbook[0][y_start+iterator][x_start+vals_iterator].present?) do
            vals << workbook[0][y_start+iterator][x_start+vals_iterator].value
            vals_iterator += 1
          end
          mappings[header] = vals
          iterator += 1
        end
      else
        raise "Illegal source type #{self.view_type} for #{self.path}"
      end
      return mappings
    end

    def _child_values(source)
      workbook = RubyXL::Parser.parse(source)
      x_start, y_start, x_stop, y_stop = _offset
      xml_content = ""
      case self.view_type
      when "horizontal"
        self.num_objects.times do |i|
          xml_content << "<#{self.parent_element}>"
          xml_content << _get_row_values(workbook, i, x_start, y_start, x_stop, y_stop)
          xml_content << "</#{self.parent_element}>"
        end
      when "vertical"
        self.num_objects.times do |i|
          xml_content << "<#{self.parent_element}>"
          xml_content << _get_column_values(workbook, i, x_start, y_start, x_stop, y_stop)
          xml_content << "</#{self.parent_element}>"
        end
      else
        raise "Illegal source type #{self.source_type[source]} for #{source}"
      end
      return xml_content
    end

    def _get_row_values(workbook, index, x_start, y_start, x_stop, y_stop)
      headers = workbook[0][y_start].cells.collect { |cell| cell.value }
      row_value = ""
      _offset = 1
      headers.each_with_index do |header,h_index|
        field_val = workbook[0][y_start+index+_offset][x_start+h_index].present? ? workbook[0][y_start+index+_offset][x_start+h_index].value : ""
        row_value << "<#{self.user_defined_mappings[header]["mapped_value"]}>#{field_val}</#{self.user_defined_mappings[header]["mapped_value"]}>" if self.user_defined_mappings[header].present?
      end
      return row_value
    end

    def _get_column_values(workbook, index, x_start, y_start, x_stop, y_stop)
      iterator = 0
      column_value = ""
      headers = Array.new
      while workbook[0][y_start+iterator].present? do
        headers << workbook[0][y_start+iterator][x_start].value
        iterator += 1
      end
      _offset = 1
      headers.each_with_index do |header,h_index|
        field_val = workbook[0][y_start+h_index][index+_offset].present? ? workbook[0][y_start+h_index][index+_offset].value : ""
        column_value << "<#{self.user_defined_mappings[header]["mapped_value"]}>#{field_val}</#{self.user_defined_mappings[header]["mapped_value"]}>"
      end
      return column_value
    end

    def _build_preservation_xml(filename, content)
      tmp_filename = "#{filename}.tmp"
      if File.basename(filename) == self.metadata_builder.repo.preservation_filename
        xml_review_status = generate_review_status_xml
        content << xml_review_status
      end
      File.open(tmp_filename, "w+") do |f|
        f << $xml_header << content << $xml_footer
      end
      File.rename(tmp_filename, filename)
    end

    def _offset
      x_start = self.x_start - 1
      y_start = self.y_start - 1
      x_stop = self.x_stop - 1
      y_stop = self.y_stop - 1
      return x_start, y_start, x_stop, y_stop
    end

    def _strip_headers(xml)
      xml.gsub!($xml_header, "") && xml.gsub!($xml_footer, "")
    end

    def self.sheet_types
      sheet_types = [["Vertical", "vertical"], ["Horizontal", "horizontal"]]
    end

    def self.source_types
      source_types = [["Voyager BibID Lookup", "voyager"], ["Custom", "custom"]]
    end

end
