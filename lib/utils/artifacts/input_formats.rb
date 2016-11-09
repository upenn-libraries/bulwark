module Utils
  module Artifacts

    class Xml

      attr_reader :file_name

      def initialize(repo)
        @file_name = "#{repo.names.filename.xmlify}"
      end

    end

    module InputFormats

      def self.fetch(repo)
        a = Utils::Artifacts::Xml.new(repo)
        a.file_name
      end

    end
  end
end