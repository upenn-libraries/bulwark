module Bulwark
  class Import
    class JhoveOutput
      attr_reader :document

      def initialize(filepath)
        @document = File.open(filepath) { |f| Nokogiri::XML(f) }
      end

      # Returns mime type.
      #
      # @return [nil] if no mime type present
      # @return [String] if mime type present
      def mime_type_for(filename)
        @document.at_xpath("/xmlns:jhove/xmlns:repInfo[@uri='#{filename}']/xmlns:mimeType")&.text
      end

      def size_for(filename)
        @document.at_xpath("/xmlns:jhove/xmlns:repInfo[@uri='#{filename}']/xmlns:size")&.text.to_i
      end
    end
  end
end
