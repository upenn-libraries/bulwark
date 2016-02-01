module Utils
  class << self

    def config
      @config ||= Utils::Configuration.new
    end

    def configure
      yield config
    end

    def generate_checksum_log
      b = Utils::Manifests::Checksum.new("sha256")
      Dir.glob "#{Utils.config.assets_path}/*" do |directory|
        begin
          manifest, file_list = Utils::Preprocess.build_for_preprocessing(directory)
          checksum_path = "#{directory}/#{Utils.config.object_admin_path}/checksum.tsv"
          b.calculate(file_list)
          checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, b.content)
          checksum_manifest.save
        rescue
          Rails.logger.debug "WARNING: No filesystem manifest found at #{directory}, skipping..."
          next
        end
      end
      return { :success => "Checksum log generated" }
    end

    def import_to_fedora
      Dir.glob "#{Utils.config.imports_local_staging}/#{Utils.config.repository_prefix}*.xml" do |file|
        Utils::Process.import(file)
      end
    end

  end
end
