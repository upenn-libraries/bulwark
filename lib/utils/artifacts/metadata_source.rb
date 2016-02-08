module Utils
  module Artifacts
    class MetadataSource

      TYPES=["tbd", "structural","descriptive","technical","administrative"]
      UNIT_FORMATS=["xml", "xlsx", "csv"]

      attr_accessor :type, :path, :unit_format

      def initialize(type = "tbd", path, unit_format)
        @type = validate_source(type, TYPES)
        @unit_format = validate_source(unit_format, UNIT_FORMATS)
        @path = path
      end

      private

      def validate_source(value, array)
        value.downcase!
        if array.include?(value)
          return value
        else
          raise "\"#{value}\" is not valid against array."
        end
      end

    end
  end
end
