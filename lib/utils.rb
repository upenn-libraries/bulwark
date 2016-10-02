require 'roo'
require 'pathname'

module Utils

  class << self

    def generate_checksum_log(directory)
      checksum_agent = Utils::Manifests::Checksum.new('sha256')
      file_list = Dir.glob("#{directory}/*")
      checksum_path = "#{directory}/#{Utils.config[:object_admin_path]}/checksum.tsv"
      checksum_agent.calculate(file_list)
      checksum_manifest = Utils::Manifests::Manifest.new(Utils::Manifests::Checksum, checksum_path, checksum_agent.content)
      checksum_manifest.save
      { :success => I18n.t('colenda.utils.success.checksum_log_generated') }
    end

  end
end
