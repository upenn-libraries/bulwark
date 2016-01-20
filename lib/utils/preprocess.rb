module Utils
  module Preprocess

      def get_filesystem_manifest_hash(path)
        begin
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
          manifest = manifest_keys_array.zip(manifest_values_array).to_h
          return manifest
        end
      end
    end
  end
end
