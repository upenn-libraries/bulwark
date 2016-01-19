module Utils
  module Manifests
    class Manifest

    attr_accessor :type, :path, :content
    def initialize(type, path, content)
      @type = type
      @path = path
      @content = content
      @temp_path = "tmp/#{path}"
    end

    def save
      create_manifest
      migrate
    end

    private
      # def assemble_content(raw_content)
      #
      # end

      def create_manifest
        unless File.exist?(File.dirname(@temp_path))
          FileUtils.mkdir_p(File.dirname(@temp_path))
        end
        File.open(@temp_path, "w+") do |f|
          f.write(@content)
        end
      end

      def migrate
        begin
          FileUtils.mv(@temp_path, @path)
        rescue Exception
          puts "Destination #{@path} does not exist.  Manifest not saved properly."
        end
      end
    end
  end
end
