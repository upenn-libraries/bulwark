require 'digest'
module Utils
  module Manifests
    class Checksum


      attr_accessor :hash_type, :content, :checksums_hash

      def initialize(hash_type)
        begin
          @filesystem_yml = "#{Rails.root}/config/filesystem.yml"
          @manifests_yml = "#{Rails.root}/config/manifests.yml"
          @fs_config = YAML.load_file(File.expand_path(@filesystem_yml, __FILE__))
          @manifests_config = YAML.load_file(File.expand_path(@manifests_yml, __FILE__))
          @hash_type = hash_type
          @digest = set_digest(@hash_type)
          @checksums_hash = Hash.new
        rescue
          raise $!, "Checksumming agent not created due to the following error(s): #{$!}", $!.backtrace
        end
      end

      def calculate(file_list)
        @checksums_hash = Hash.new
        file_list.each do |file_to_check|
          checksum = @digest.file file_to_check
          @checksums_hash[file_to_check] = checksum.hexdigest
        end
        @content = format_content(file_list)
      end

      private
        def set_digest(hash_type)
          case hash_type.downcase
            when 'sha256'
              digest = Digest::SHA256
            when 'sha1'
              digest = Digest::SHA1
            when 'sha2'
              digest = Digest::SHA2
            when 'md5'
              digest = Digest::MD5
            when 'rmd160'
              digest = Digest::RMD160
            else
              raise "#{@hash_type} is not a valid hash type."
          end
          digest
        end

        def format_content(file_list)
          hash_separated = ''
          @checksums_hash.each do |v|
            arr = v.flatten.join('\t')
            hash_separated += arr
            hash_separated += '\n'
          end
          file_list.each do |item|
            item.gsub!(@fs_config['development']['federated_fs_path'], @fs_config['development']['assets_path'])
          end
          hash_separated
        end

    end
  end
end
