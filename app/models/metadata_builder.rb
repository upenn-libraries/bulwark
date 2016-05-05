class MetadataBuilder < ActiveRecord::Base

  belongs_to :repo, :foreign_key => "repo_id"

  include Utils

  validates :parent_repo, presence: true

  validate :check_for_errors

  serialize :source
  serialize :source_type
  serialize :source_coordinates
  serialize :preserve
  serialize :nested_relationships
  serialize :source_mappings
  serialize :field_mappings

  @@xml_tags = Array.new
  @@error_message = nil

  @@xml_header = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><root>"
  @@xml_footer = "</root>"

  def nested_relationships=(nested_relationships)
    nested_relationships.reject!(&:empty?)
    self[:nested_relationships] = nested_relationships
  end

  def field_mappings=(field_mappings)
    self[:field_mappings] = eval(field_mappings)
  end

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def nested_relationships
    read_attribute(:nested_relationships) || ''
  end

  def source
    read_attribute(:source) || ''
  end

  def source_type
    read_attribute(:source_type) || ''
  end

  def source_coordinates
    read_attribute(:source_coordinates) || ''
  end

  def preserve
    read_attribute(:preserve) || ''
  end

  def source_mappings
    read_attribute(:source_mappings) || ''
  end

  def field_mappings
    read_attribute(:field_mappings) || ''
  end

  def parent_repo
    read_attribute(:parent_repo) || ''
  end

  def available_metadata_files
    available_metadata_files = Array.new
    self.repo.version_control_agent.clone
    Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*") do |file|
      available_metadata_files << file
    end
    self.repo.version_control_agent.delete_clone
    return available_metadata_files
  end

  def unidentified_files
    identified = (self.source + self.preserve).uniq!
    unidentified = self.available_metadata_files - identified
    return unidentified
  end

  def set_source(source_files)
    self.source = source_files.values
    self.save!
  end

  def set_source_specs(source_specs)
    self.source_type = source_specs["source_type"]
    self.source_coordinates = source_specs["source_coordinates"]
    self.save!
  end

  def set_preserve(preserve_files)
    self.preserve = preserve_files.values
    self.save!
  end

  def set_metadata_mappings
    self.repo.version_control_agent.clone
    self.source_mappings = convert_metadata
    self.repo.version_control_agent.delete_clone
    self.save!
  end

  def clear_unidentified_files
    unidentified_files = self.unidentified_files
    self.repo.version_control_agent.clone
    unidentified_files.each do |f|
      self.repo.version_control_agent.unlock(f)
      self.repo.version_control_agent.drop(:drop_location => f) && `rm -rf #{f}`
    end
    self.repo.version_control_agent.commit("Removed files not identified as metadata source and/or for long-term preservation: #{unidentified_files}")
    self.repo.version_control_agent.push
    self.repo.version_control_agent.delete_clone
  end

  def verify_xml_tags(tags_submitted)
    errors = Array.new
    tag_sets = eval(tags_submitted)
    tag_sets.each do |tag_set|
      tag_set.drop(1).each do |tag|
        tag.each do |val|
          error = _validate_xml_tag(val.last["mapped_value"])
          errors << error unless error.nil?
        end
      end
    end
    @@error_message = errors
    return @@error_message
  end

  def build_xml_files
    xml_files = Array.new
    self.set_metadata_mappings
    self.repo.version_control_agent.clone
    self.source_mappings.each do |file|
      @xml_content = ""
      fname = file.first.last
      xml_fname = "#{fname}.xml"
      xml_unified_filename_fname = "#{xml_fname}.tmp"
      xml_files << xml_fname
      if self.field_mappings["#{fname}"]["child_element"]["mapped_value"].empty?
        file.drop(1).each do |source|
          tag = self.field_mappings["#{fname}"]["#{source.first}"]["mapped_value"]
          source.last.each do |field_value|
            @xml_content << "<#{tag}>#{field_value}</#{tag}>"
          end
        end
      else
        @xml_content << each_row_values(fname)
      end
      unless self.field_mappings["#{fname}"]["root_element"]["mapped_value"].empty?
        root_element = self.field_mappings["#{fname}"]["root_element"]["mapped_value"]
        @xml_content_final_copy = "<#{root_element}>#{@xml_content}</#{root_element}>"
      else
        @xml_content_final_copy = @xml_content
      end
      _build_preservation_xml(xml_fname, @xml_content_final_copy)
      begin
        self.repo.version_control_agent.commit("Generated preservation XML for #{fname}")
      rescue Git::GitExecuteError
        next
      end
    end
    self.repo.version_control_agent.push
    generate_parent_child_xml if self.nested_relationships.present?
    set_preserve_files(xml_files)
    self.repo.version_control_agent.delete_clone
  end

  def generate_parent_child_xml
    self.nested_relationships.each do |rel|
      rel = eval(rel)
      key, value = rel.first
      metadata_path = "#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}"
      self.repo.version_control_agent.get(:get_location => metadata_path)
      key_xml_path = "#{key}.xml"
      child_xml_path = "#{self.repo.version_control_agent.working_path}#{value}.xml"
      xml_content = File.open(key_xml_path, "r"){|io| io.read}
      child_xml_content = File.open(child_xml_path, "r"){|io| io.read}
      _strip_headers(xml_content) && _strip_headers(child_xml_content)
      end_tag = "</#{self.field_mappings[key]["root_element"]["mapped_value"]}>"
      insert_index = xml_content.index(end_tag)
      xml_content.insert(insert_index, child_xml_content)
      xml_unified_filename = "#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/#{self.repo.preservation_filename}"
      self.repo.version_control_agent.unlock(xml_unified_filename) if File.exists?(xml_unified_filename)
      _build_preservation_xml(xml_unified_filename,xml_content)
      FileUtils.rm(key_xml_path)
      FileUtils.rm(child_xml_path)
      begin
        self.repo.version_control_agent.commit("Generated unified XML for #{key} and #{value} at #{xml_unified_filename}")
      rescue Git::GitExecuteError
        next
      end
      self.repo.version_control_agent.push
      set_preserve_files(xml_unified_filename)
      self.save!
    end
  end

  def check_for_errors
    if @@error_message
      errors.add(:source, "XML tag error(s): #{@@error_message}") unless @@error_message.empty?
    end
  end

  def transform_and_ingest(array)
    begin
      @vca = self.repo.version_control_agent
      array.each do |p|
        key, val = p
        @vca.clone
        _get_metadata_repo_content
        @vca.unlock(val)
        transformed_repo_path = "#{Utils.config.transformed_dir}/#{@vca.remote_path.gsub("/","_")}"
        Dir.mkdir(transformed_repo_path) && Dir.chdir(transformed_repo_path)
        `xsltproc #{Rails.root}/lib/tasks/sv.xslt #{val}`
        @status = self.repo.ingest(transformed_repo_path)
        @vca.reset_hard
        @vca.delete_clone
        FileUtils.rm_rf(transformed_repo_path, :secure => true) if File.directory?(transformed_repo_path)
      end
      return @status.present? ? {:success => "Item re-ingested into the repository.  See link(s) below to preview ingested items associated with this repo."} : {:success => "Ingestion complete.  See link(s) below to preview ingested items associated with this repo." }
    rescue
      return { :error => "Something went wrong during ingestion.  Check logs for more information." }
    end
  end

  private

    def convert_metadata
      begin
        repo = _get_metadata_repo_content
        @mappings_sets = Array.new
        self.source.each do |source|
          pathname = Pathname.new(source)
          ext = pathname.extname.to_s[1..-1]
          case ext
          when "xlsx"
            @mappings = generate_mapping_options_xlsx(source)
            @mappings_sets << @mappings
          else
            raise "Illegal metadata source unit type"
          end
        end
        return @mappings_sets
      rescue
        raise $!, "Metadata conversion failed due to the following error(s): #{$!}", $!.backtrace
      end
    end

    def generate_mapping_options_csv(base_file, tmp_csv)
      mappings = {}
      mappings["base_file"] = "#{base_file}"
      headers = CSV.open(tmp_csv, 'r') { |csv| csv.first }
      headers.each{|a| mappings[a] = 0}
      headers.each do |header|
        sample_vals = Array.new
        CSV.foreach(tmp_csv, :headers => true) do |row|
          sample_vals << row["#{header}"] unless row["#{header}"].nil?
        end
        mappings["#{header}"] = sample_vals
      end
      return mappings
    end

    def generate_mapping_options_xlsx(source)
      mappings = {}
      mappings["base_file"] = "#{source}"
      headers = Array.new
      iterator = 0

      x_start = _offset(self.source_coordinates[source]["x_start"].to_i)
      y_start = _offset(self.source_coordinates[source]["y_start"].to_i)

      x_stop = _offset(self.source_coordinates[source]["x_stop"].to_i)
      y_stop = _offset(self.source_coordinates[source]["y_stop"].to_i)

      workbook = RubyXL::Parser.parse(source)
      case self.source_type[source]
      when "horizontal"
        while((x_stop >= (x_start+iterator)) && (workbook[0][y_start][x_start+iterator].present?))
          header = workbook[0][y_start][x_start+iterator].value
          headers << header
          vals = Array.new
          #This variable could eventually be user-defined in order to let the user set the values offset
          vals_iterator = 1
          while(workbook[0][y_start+vals_iterator].present? && workbook[0][y_start+vals_iterator][x_start+iterator].present?) do
            vals << workbook[0][y_start+vals_iterator][x_start+iterator].value
            vals_iterator += 1
          end
          mappings[header] = vals
          iterator += 1
        end
      when "vertical"
        while((y_stop >= (y_start+iterator)) && (workbook[0][y_start+iterator].present?))
          headers << workbook[0][y_start+iterator][x_start].value
          iterator += 1
        end
      else
        raise "Illegal source type for #{source}"
      end
      return mappings
    end

    def each_row_values(base_file)
      repo = _get_metadata_repo_content
      tmp_csv = convert_to_csv(base_file)
      child_element = self.field_mappings[base_file]["child_element"]["mapped_value"]
      xml_content = ""
      CSV.foreach(tmp_csv, :headers => true) do |row|
        xml_content << "<#{child_element}>"
        row.to_a.each do |value|
          tag = self.field_mappings[base_file]["#{value.first}"]["mapped_value"]
          xml_content << "<#{tag}>#{value.last}</#{tag}>"
        end
        xml_content << "</#{child_element}>"
      end
      return xml_content

    end

    def convert_to_csv(source)
      xlsx = Roo::Spreadsheet.open(source)
      tmp_csv = "#{Rails.root}/tmp/#{source.gsub("/","_").to_s}.csv"
      File.open(tmp_csv, "w+") do |f|
        f.write(xlsx.to_csv)
      end
      return tmp_csv
    end

    def set_preserve_files(pfiles)
      if self.preserve.present?
        self.preserve += self.preserve + Array(pfiles).uniq
      else
        self.preserve = Array(pfiles).uniq
      end
      self.preserve.uniq!
      self.save!
    end

    def _get_metadata_repo_content
      repo = Repo.find(self.repo_id)
      repo.version_control_agent.get(:get_location => "#{repo.version_control_agent.working_path}/#{repo.metadata_subdirectory}")
      return repo
    end

    def _validate_xml_tag(tag)
      error_message = Array.new
      error_message << "Valid XML tags cannot start with #{tag.first_three} (detected in field \"#{tag}\")" if tag.starts_with_xml?
      error_message << "Valid XML tags cannot contain spaces (detected in field \"#{tag}\")" if tag.include?(" ")
      error_message << "Valid XML tags cannot begin with numbers (detected in field \"#{tag}\")" if tag.starts_with_number?
      return error_message unless error_message.empty?
    end

    def _build_preservation_xml(filename, content)
      tmp_filename = "#{filename}.tmp"
      File.open(tmp_filename, "w+") do |f|
        f << @@xml_header << content << @@xml_footer
      end
      File.rename(tmp_filename, filename)
    end

    def _strip_headers(xml)
      xml.gsub!(@@xml_header, "") && xml.gsub!(@@xml_footer, "")
    end

    def _offset(coordinate)
      coordinate = coordinate-1 unless coordinate == 0
      return coordinate
    end

    def self.sheet_types
      sheet_types = [["Vertical", "vertical"], ["Horizontal", "horizontal"]]
    end

end
