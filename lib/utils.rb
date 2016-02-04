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

  end
end
