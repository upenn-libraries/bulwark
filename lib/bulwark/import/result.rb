# frozen_string_literal: true

module Bulwark
  class Import
    class Result
      SUCCESS = 'success'
      FAILED = 'failed'

      attr_reader :unique_identifier, :status, :errors

      def initialize(status:, errors: [], unique_identifier: nil)
        @status = status
        @errors = errors
        @unique_identifier = unique_identifier
      end
    end
  end
end
