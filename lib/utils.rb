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

    def index
      ActiveFedora::Base.reindex_everything
    end
  end
end
