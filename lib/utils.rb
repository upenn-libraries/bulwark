require 'roo'
require 'pathname'

module Utils
  class << self

    def config
      @config ||= Utils::Configuration.new
    end

    def configure
      yield config
    end

    def generate_checksum_log(directory)
      b = Utils::Manifests::Checksum.new("sha256")
      begin
        manifest, file_list = Utils::Preprocess.build_for_preprocessing(directory)
        unless file_list.empty?
          checksum_path = "#{directory}/#{Utils.config.object_admin_path}/checksum.tsv"
          b.calculate(file_list)
          checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, b.content)
          checksum_manifest.save
        else
          return {:error => "No files detected for #{directory}/#{manifest[Utils.config.file_path_label]}"}
        end
        return { :success => "Checksum log generated" }
      end
    end

    def fetch_and_convert_files
      begin
        Dir.glob "#{Utils.config.assets_path}/*" do |directory|
          begin
            manifest, file_list = Utils::Preprocess.build_for_preprocessing(directory)
            manifest.each { |k, v| manifest[k] = v.prepend("#{directory}/") }
            f = File.readlines(manifest["#{Utils.config.metadata_path_label}"])
            index = f.index("  </record>\n")
            f.insert(index, "    <file_list>\n","    </file_list>\n") unless file_list.empty?
            flist_index = f.index("    <file_list>\n")
            file_list.each do |file_name|
              file_name.gsub!(Utils.config.assets_path, Utils.config.federated_fs_path)
              f.insert((flist_index+1), "      <file>#{file_name}</file>")
            end
            File.open("tmp/structure.xml", "w+") do |updated_metadata|
              updated_metadata.puts(f)
            end
            `xsltproc #{Rails.root}/lib/tasks/sv.xslt tmp/structure.xml`
          rescue SystemCallError
            next
          end
        end
        return {:success => "Files fetched and converted successfully, ready for ingest."}
      rescue
        return {:error => "Something went wrong while attempting to fetch files.  Check application logs."}
      end
    end

    def import
      begin
        Dir.glob "#{Utils.config.imports_local_staging}/#{Utils.config.repository_prefix}*.xml" do |file|
          Utils::Process.import(file)
        end
        return {:success => "All items imported successfully."}
      rescue
        return {:error => "Something went wrong during ingest.  Consult Fedora logs."}
      end
    end

    def index
      ActiveFedora::Base.reindex_everything
    end

    def convert_metadata(repo)
      begin
        repo.metadata_sources.each do |source|
          case source[:unit_type]
          when "xlsx"
            xlsx = Roo::Spreadsheet.open(source[:path])
            tmp_csv = "tmp/#{Pathname.new(source[:path]).basename.to_s}.csv"
            File.open(tmp_csv, "w+") do |f|
              f.write(xlsx.to_csv)
            end
            @mappings = generate_mapping_options_csv(tmp_csv)
          when "csv"
            @mappings = generate_mapping_options_csv(tmp_csv)
          when "xml"
          else
            raise "Illegal metadata source unit type"
          end
        end
        return @mappings, {:success => "See metadata mapping options below"}
      rescue
        return {:error => "Metadata conversion failed.  See log for errors."}
      end
    end

    def generate_mapping_options_csv(base_file)
      mappings = {}

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
end
