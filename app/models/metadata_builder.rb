class MetadataBuilder < ActiveRecord::Base

  belongs_to :repo, :foreign_key => "repo_id"

  include Utils

  after_create :set_source

  validates :parent_repo, presence: true

  validate :check_for_errors

  serialize :source
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

  def set_source(source_files)
    self.source = source_files.values
    self.save!
  end

  def set_preserve(preserve_files)
    self.preserve = preserve_files.values
    self.save!
  end


#TODO: Deprecated -- remove
  def set_source_get_mappings
    metadata_sources = Array.new
    self.repo.version_control_agent.clone
    Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*") do |file|
      metadata_sources << file
    end
    status = Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*").empty? ? { :error => "No metadata sources detected." } : { :success => "Metadata sources detected -- see output below." }
    self.source = metadata_sources
    self[:source_mappings] = convert_metadata
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
    self.repo.version_control_agent.clone
    self[:source_mappings] = convert_metadata
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
    self.repo.version_control_agent.delete_clone
    generate_parent_child_xml if self.nested_relationships.present?
    set_preserve_files(xml_files)
  end

  def generate_parent_child_xml
    self.nested_relationships.each do |rel|
      rel = eval(rel)
      key, value = rel.first
      metadata_path = "#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}"
      self.repo.version_control_agent.clone
      self.repo.version_control_agent.get(:get_location => metadata_path)
      child_path = "#{self.repo.version_control_agent.working_path}#{value}"
      xml_content = File.open(key, "r"){|io| io.read}
      child_xml_content = File.open(child_path, "r"){|io| io.read}
      _strip_headers(xml_content) && _strip_headers(child_xml_content)
      key_index = key.gsub(".xml","")
      val_index = key.gsub(".xml","")
      end_tag = "</#{self.field_mappings[key_index]["root_element"]["mapped_value"]}>"
      insert_index = xml_content.index(end_tag)
      xml_content.insert(insert_index, child_xml_content)
      xml_unified_filename = "#{key_index}.#{Time.now.to_i}.xml"
      self.repo.version_control_agent.unlock(xml_unified_filename) if File.exists?(xml_unified_filename)
      _build_preservation_xml(xml_unified_filename,xml_content)
      begin
        self.repo.version_control_agent.commit("Generated unified XML for #{key} and #{value} at #{xml_unified_filename}")
      rescue Git::GitExecuteError
        self.repo.version_control_agent.delete_clone
        next
      end
      self.repo.version_control_agent.push
      self.repo.version_control_agent.delete_clone
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
        @vca.reset_hard
        @vca.delete_clone
        @status = self.repo.ingest(transformed_repo_path)
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
            tmp_csv = convert_to_csv(source)
            @mappings = generate_mapping_options_csv(source, tmp_csv)
            @mappings_sets << @mappings
          when "csv"
            @mappings = generate_mapping_options_csv(source, tmp_csv)
            @mappings_sets << @mappings
          when "xml"
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

end
