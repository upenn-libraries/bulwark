class MetadataBuilder < ActiveRecord::Base

  belongs_to :repo, :foreign_key => "repo_id"

  include Utils

  after_create :set_source

  validates :parent_repo, presence: true

  validate :check_for_errors

  serialize :source
  serialize :source_mappings
  serialize :field_mappings
  serialize :xml

  @@xml_tags = Array.new
  @@error_message = nil

  def field_mappings=(field_mappings)
    self[:field_mappings] = eval(field_mappings)
  end

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def set_source
    metadata_sources = Array.new
    self.repo.version_control_agent.clone
    Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*") do |file|
      metadata_sources << file
    end
    status = Dir.glob("#{self.repo.version_control_agent.working_path}/#{self.repo.metadata_subdirectory}/*").empty? ? { :error => "No metadata sources detected." } : { :success => "Metadata sources detected -- see output below." }
    self.repo.version_control_agent.delete_clone
    self.source = metadata_sources
    self[:source_mappings] = convert_metadata
  end

  def to_xml(mapping)
    fname = mapping.first.last
    mapping.drop(1).each do |row|
      key = row.first
      field_key = (self.field_mappings.nil? ? row.first : self.field_mappings["#{fname}"]["#{key}"]["mapped_value"])
      @xml_content = "<root>"
      row.last.each do |value|
        @xml_content << "<#{field_key}>#{value}</#{field_key}>"
      end
      @xml_content << "</root>"
    end

    return @xml_content
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

  def build_xml_files(xml_hash)
    _get_metadata_source
    xml_hash.each do |xml|
      fname = "#{xml.first}.xml"
      xml_content = to_xml(eval(xml.last))
      if xml_content.empty?
        self.repo.version_control_agent.delete_clone
        break
      else
        File.open(fname, "w+") do |file|
          file << xml_content
        end
      end
    end
  end

  def check_for_errors
    if @@error_message
      errors.add(:parent_element, "XML tag error(s): #{@@error_message}") unless @@error_message.empty?
    end
  end

  private

    def convert_metadata
      begin
        _get_metadata_source
        @mappings_sets = Array.new
        self.source.each do |source|
          pathname = Pathname.new(source)
          ext = pathname.extname.to_s[1..-1]
          case ext
          when "xlsx"
            xlsx = Roo::Spreadsheet.open(source)
            tmp_csv = "#{repo.version_control_agent.working_path}/#{repo.metadata_subdirectory}/#{pathname.basename.to_s}.csv"
            File.open(tmp_csv, "w+") do |f|
              f.write(xlsx.to_csv)
            end
            @mappings = generate_mapping_options_csv(tmp_csv)
            @mappings_sets << @mappings
          when "csv"
            @mappings = generate_mapping_options_csv(tmp_csv)
            @mappings_sets << @mappings
          when "xml"
          else
            raise "Illegal metadata source unit type"
          end
        end
        repo.version_control_agent.delete_clone(:drop_location => "#{repo.version_control_agent.working_path}/#{repo.metadata_subdirectory}")
        return @mappings_sets
      rescue
        raise $!, "Metadata conversion failed due to the following error(s): #{$!}", $!.backtrace
      end
    end

    def generate_mapping_options_csv(base_file)
      mappings = {}
      mappings["base_file"] = "#{base_file.sub('tmp/','')}"
      headers = CSV.open(base_file, 'r') { |csv| csv.first }
      headers.each{|a| mappings[a] = 0}
      headers.each do |header|
        sample_vals = Array.new
        CSV.foreach(base_file, :headers => true) do |row|
          sample_vals << row["#{header}"] unless row["#{header}"].nil?
        end
        mappings["#{header}"] = sample_vals
      end
      return mappings
    end

    def _get_metadata_source
      repo = Repo.find(self.repo_id)
      repo.version_control_agent.clone
      repo.version_control_agent.get(:get_location => "#{repo.version_control_agent.working_path}/#{repo.metadata_subdirectory}")
    end

    def _validate_xml_tag(tag)
      error_message = Array.new
      error_message << "Valid XML tags cannot start with #{tag.first_three} (detected in field \"#{tag}\")" if tag.starts_with_xml?
      error_message << "Valid XML tags cannot contain spaces (detected in field \"#{tag}\")" if tag.include?(" ")
      error_message << "Valid XML tags cannot begin with numbers (detected in field \"#{tag}\")" if tag.starts_with_number?
      return error_message unless error_message.empty?
    end

end
