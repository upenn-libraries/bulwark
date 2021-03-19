# frozen_string_literal: true

class DigitalObjectImport < ActiveRecord::Base
  QUEUED = 'queued'
  IN_PROGRESS = 'in progress'
  FAILED = 'failed'
  SUCCESSFUL = 'successful'
  STATUSES = [QUEUED, IN_PROGRESS, FAILED, SUCCESSFUL].freeze

  belongs_to :bulk_import
  belongs_to :repo

  paginates_per 10
  max_paginates_per 100

  serialize :process_errors, Array
  serialize :import_data, JSON

  before_validation :set_default_status, on: :create

  validates :status, inclusion: { in: STATUSES }

  # status helpers
  STATUSES.each do |s|
    define_method "#{s.tr(' ', '_')}?" do
      status == s
    end
  end

  def process
    update(status: IN_PROGRESS)

    begin_time = Time.zone.now
    data = import_data.symbolize_keys
    result = if data[:action]&.downcase == Bulwark::Migrate::ACTION
               Bulwark::Migrate.new(migrated_by: bulk_import.created_by, **data).process
             else
               Bulwark::Import.new(created_by: bulk_import.created_by, **data).process
             end
    update(
      status: result.status,
      process_errors: result.errors,
      repo: result.repo,
      duration: (Time.zone.now - begin_time).to_i
    )
  end

  private

    def set_default_status
      self.status = QUEUED unless status
    end
end
