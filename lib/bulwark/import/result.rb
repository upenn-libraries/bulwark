# frozen_string_literal: true

module Bulwark
  class Import
    class Result
      attr_reader :repo, :status

      def initialize(status:, errors: [], repo: nil)
        @status = status
        @errors = errors
        @repo = repo
      end

      # Truncate error message to avoid MySQL TEXT field byte limit
      def errors
        return @errors if @errors.empty?

        char_limit = 60_000 / @errors.length
        @errors.map { |e| e.truncate char_limit }
      end
    end
  end
end
