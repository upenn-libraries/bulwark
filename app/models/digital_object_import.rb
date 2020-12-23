# frozen_string_literal: true

class DigitalObjectImport < ActiveRecord::Base
  QUEUED = 'queued'
  IN_PROGRESS = 'in_progress'
  FAILED = 'failed'
  SUCCESSFUL = 'successful'
  STATUSES = [QUEUED, IN_PROGRESS, FAILED, SUCCESSFUL].freeze

  belongs_to :bulk_import

  serialize :process_errors, Array
  serialize :import_data, JSON

  after_initialize :set_default_status

  validates :status, inclusion: { in: STATUSES }

  # status helpers
  STATUSES.each do |s|
    define_method "#{s}?" do
      status == s
    end
  end

  private

    def set_default_status
      self.status = QUEUED
    end
end
