require 'roo'
require 'pathname'

module Utils

  class << self

    def generate_checksum_log(directory)
      b = Utils::Manifests::Checksum.new("sha256")
      begin
        manifest, file_list = Utils::Preprocess.build_for_preprocessing(directory)
        unless file_list.empty?
          checksum_path = "#{directory}/#{Utils.config[:object_admin_path]}/checksum.tsv"
          b.calculate(file_list)
          checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, b.content)
          checksum_manifest.save
        else
          return {:error => I18n.t('colenda.utils.warnings.no_files')}
        end
        return { :success => I18n.t('colenda.utils.success.checksum_log_generated') }
      end
    end

  end
end
