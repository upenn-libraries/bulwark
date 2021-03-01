# frozen_string_literal: true

module Bulwark
  # queue-related stuff for BulkImports, etc.
  class Queues
    PRIORITY_QUEUES = %w[high medium low].freeze
    DEFAULT_PRIORITY = 'medium'
  end
end
