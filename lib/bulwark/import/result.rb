# frozen_string_literal: true

module Bulwark
  class Import
    class Result
      attr_reader :repo, :status, :errors

      def initialize(status:, errors: [], repo: nil)
        @status = status
        @errors = errors
        @repo = repo
      end
    end
  end
end
