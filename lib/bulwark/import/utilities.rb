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
    end
  end
end
