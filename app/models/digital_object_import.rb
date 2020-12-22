# frozen_string_literal: true

class DigitalObjectImport < ActiveRecord::Base
  STATUSES = [:queued, :in_progress, :failed, :successful].freeze

  belongs_to :bulk_import

  serialize :process_errors, Array
  serialize :item_data, JSON

  validates :status, inclusion: { in: STATUSES }
end
