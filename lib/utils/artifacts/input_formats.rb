require 'open-uri'

module Utils
  module Artifacts

    class Xml

      attr_reader :file_name

      def initialize(metadata_source)
        input_source_prefix = Utils.config[:input_source_prefix].present? ? Utils.config[:input_source_prefix] : 'input_source'
        @file_name = "#{input_source_prefix}_#{metadata_source.source_type}_#{metadata_source.id}".xmlify
      end

      def fetch_from_endpoint(endpoint)
        file = open(endpoint)
        IO.copy_stream(file, self.file_name)
      end

    end

    module InputFormats

      def fetch_input_artifact(artifact_type)
        klass_string = "Utils::Artifacts::#{artifact_type}"
        raise Utils::Error::InputFormats.new(I18n.t('colenda.utils.metadata_source.errors.invalid_input_format', :input_format => artifact_type)) unless Object.const_defined?(klass_string)
        klass = Object.const_get klass_string
        artifact = klass.new(self)
        artifact.fetch_from_endpoint(self.input_source)
        artifact.file_name
      end

    end
  end
end