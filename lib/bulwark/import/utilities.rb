# frozen_string_literal: true

module Bulwark
  class Import
    module Utilities
      # Queries EZID to check if a given ark already exists.
      #
      # @return true if ark exists
      # @return false if ark does not exist
      def self.ark_exists?(ark)
        Ezid::Identifier.find(ark)
        true
      rescue Ezid::Error => e
        false
      end

      # Converts structural data given in Bulk Import CSV to a structural-only CSV.
      def self.structural_metadata_csv(metadata_options)
        if (ordered_filenames = metadata_options[:filenames])
          # Generate structural metadata file based on contents in Bulk import csv given or path given.
          CSV.generate do |csv|
            csv << ['filename', 'sequence']
            ordered_filenames.split(';').map(&:strip).each_with_index do |f, i|
              csv << [f, i + 1]
            end
          end
        elsif metadata_options[:drive] && metadata_options[:path]
          filepath = File.join(MountedDrives.path_to(metadata_options[:drive]), metadata_options[:path])
          raise 'structural metadata path must lead to a file.' unless File.file?(filepath)
          File.read(filepath)
        else
          nil
        end
      end
    end
  end
end
