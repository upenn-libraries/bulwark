class MetadataBuilder < ActiveRecord::Base

  belongs_to :repo

  include Utils

  before_validation :set_source

  validates :parent_repo, presence: true
  validates :source, presence: true

  serialize :source
  serialize :field_mappings
  serialize :xml

  def field_mappings=(field_mappings)
    self[:field_mappings] = eval(field_mappings)
  end

  def parent_repo=(parent_repo)
    self[:parent_repo] = parent_repo
    @repo = Repo.find(parent_repo)
    self.repo = @repo
  end

  def set_source
    repo = Repo.find(self.parent_repo)
    repo.set_metadata_sources
    self.source = repo.metadata_sources
  end

  def prep_for_mapping
    convert_metadata
  end

  def to_xml(mapping)
    xml_content = "<root>"
    fname = mapping.first.last
    mapping.drop(1).each do |row|
      key = row.first
      field_key = self.field_mappings.nil? ? row.first : self.field_mappings["#{fname}"]["#{key}"]["mapped_value"]
      row.last.each do |value|
        xml_content << "<#{field_key}>#{value}</#{field_key}>"
      end
    end
    xml_content << "</root>"
  end

  def build_xml_files(xml_hash)
    xml_hash.each do |xml|
      fname = "tmp/#{xml.first}.xml"
      File.open(fname, "w+") do |file|
        file << to_xml(eval(xml.last))
      end
    end
  end

  private

    def convert_metadata
      begin
        @mappings_sets = Array.new
        self.source.each do |source|
          pathname = Pathname.new(source)
          ext = pathname.extname.to_s[1..-1]
          case ext
          when "xlsx"
            xlsx = Roo::Spreadsheet.open(source)
            tmp_csv = "tmp/#{pathname.basename.to_s}.csv"
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

end
