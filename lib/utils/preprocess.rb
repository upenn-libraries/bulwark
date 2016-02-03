module Utils
  module Preprocess

    extend self

    def get_filesystem_manifest_hash(path)
      manifest = Hash.new
      manifest_keys_array = Array.new
      manifest_values_array = Array.new

      f = File.readlines(path)
      f.each do |line|
        lp = line.split(":")
        lp.first.strip!
        lp.last.strip!
        manifest_keys_array.push(lp.first)
        manifest_values_array.push(lp.last)
      end
      @manifest = manifest_keys_array.zip(manifest_values_array).to_h
      return @manifest
    end

    def get_file_list(parent_directory)
      begin
        file_list = Dir.glob("#{parent_directory}/#{@manifest["#{Utils.config.file_path_label}"]}")
        return file_list
      rescue
        puts "File list could not be generated, as the manifest has not been created.  Run `Utils::Preprocess.build_for_preprocessing(#{parent_directory})` or `Utils::Preprocess.get_filesystem_manifest_hash(#{parent_directory}/#{Utils.config.object_manifest_location}) before calling this method to resolve.`"
      end
    end

    def build_for_preprocessing(parent_directory)
      manifest_path = "#{parent_directory}/#{Utils.config.object_manifest_location}"
      manifest = get_filesystem_manifest_hash(manifest_path)
      file_list = get_file_list(parent_directory)
      return manifest, file_list
      unless File.exists?(manifest_path)
        Rails.logger.debug "WARNING: No filesystem manifest found at #{manifest_path}, skipping..."
      end
    end
  end

end
