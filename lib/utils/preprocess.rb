module Utils
  module Preprocess

    extend self

    def get_filesystem_manifest_hash(path)
      manifest_keys_array = []
      manifest_values_array = []
      f = File.readlines(path)
      f.each do |line|
        lp = line.split(':')
        lp.first.strip!
        lp.last.strip!
        manifest_keys_array.push(lp.first)
        manifest_values_array.push(lp.last)
      end
      manifest_keys_array.zip(manifest_values_array).to_h
    end

    def get_file_list(parent_directory)
      begin
        file_list = Dir.glob("#{parent_directory}/#{@manifest["#{Utils.config[:file_path_label]}"]}")
        return file_list
      rescue
        raise I18n.t('colenda.utils.preprocess.warnings.no_file_list', :parent_directory => parent_directory, :object_semantics_location => Utils.config[:object_semantics_location])
      end
    end

  end

end
