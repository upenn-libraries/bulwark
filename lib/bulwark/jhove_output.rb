# frozen_string_literal: true

module Bulwark
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

    # Returns file size in bytes
    #
    # @return [nil] if no size present
    # @return [Integer] if size present
    def size_for(filename)
      @document.at_xpath("/xmlns:jhove/xmlns:repInfo[@uri='#{filename}']/xmlns:size")&.text.to_i
    end

    # Returns the filenames of all the files that are represented in the JHOVE output.
    #
    # @return [Array<String>] all filenames
    def filenames
      @document.xpath("/xmlns:jhove/xmlns:repInfo/@uri").map(&:text)
    end
  end
end
