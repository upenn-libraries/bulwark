module Utils
  module Artifacts
    class MetadataSource

      TYPES=["structural","descriptive","technical","administrative"]
      UNIT_FORMATS=["marcxml", "excel", "csv"]

      attr_accessor :type, :path, :unit_format
      def initialize(type, path, unit_format)
        @type = validate_source(type, TYPES)
        @unit_format = validate_source(unit_format, UNIT_FORMATS)
        @path = path
      end

      def validate_source(value, array)
        if array.include?(value.downcase)
          return value.downcase!
        else
          raise "\"#{value}\" is not valid against array."
        end
      end
    end
  end
end
