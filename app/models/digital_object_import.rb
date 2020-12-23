# frozen_string_literal: true

class DigitalObjectImport < ActiveRecord::Base
  STATUSES = %w[queued in_progress failed successful].freeze

  belongs_to :bulk_import

  serialize :process_errors, Array
  serialize :import_data, JSON

  after_initialize :set_default_status

  validates :status, inclusion: { in: STATUSES }

  # status helpers
  # @return [TrueClass, FalseClass]
  def queued?
    status == 'queued'
  end

  # @return [TrueClass, FalseClass]
  def in_progress?
    status == 'in_progress'
  end

  # @return [TrueClass, FalseClass]
  def failed?
    status == 'failed'
  end

  # @return [TrueClass, FalseClass]
  def successful?
    status == 'successful'
  end

  private

    def set_default_status
      self.status = :queued
    end
end
