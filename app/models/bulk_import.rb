# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  COMPLETED = 'completed'
  COMPLETED_WITH_ERRORS = 'completed with errors'
  IN_PROGRESS = 'in progress'
  QUEUED = 'queued'

  has_many :digital_object_imports, dependent: :destroy
  belongs_to :created_by, class_name: User, required: true

  # kamanari config
  paginates_per 10
  max_paginates_per 100

  # We shouldn't need to persist the job priority/queue,
  # we just need it when enqueueing the import jobs
  attr_accessor :job_priority

  delegate :email, to: :created_by, prefix: true

  # Returns 'completed', 'completed with errors', 'in progress', 'queued'
  # depending on status of the child import jobs. In progress if there are any
  # jobs in progress. Queued if all the jobs are queued. Completed if all the
  # jobs have been completed successfully. Completed with errors if at least one
  # job failed.
  def status
    return nil if digital_object_imports.empty?

    if digital_object_imports.all?(&:successful?)
      COMPLETED
    elsif imports_finished_with_failures?
      COMPLETED_WITH_ERRORS
    elsif digital_object_imports.all?(&:queued?)
      QUEUED
    else
      IN_PROGRESS
    end
  end

  def number_of_errors
    digital_object_imports.where(status: DigitalObjectImport::FAILED).count
  end

  # @return [Integer]
  def aggregate_processing_time
    digital_object_imports.sum(:duration)
  end

  # Returns Hash with validation errors. Errors are organized by row number. The
  # keys in the hash are the rows and the values are the errors corresponding to
  # that row.
  def validation_errors(csv)
    validation_errors = {}
    rows = Bulwark::StructuredCSV.parse(csv)
    rows.each_with_index do |row, index|
      row = row.symbolize_keys
      import = Bulwark::Import.new(created_by: created_by, **row)

      unless import.validate
        validation_errors["row #{index + 2}"] = import.errors
      end
    end
    validation_errors.blank? ? nil : validation_errors
  end

  # @param [String] csv file content
  # @param [String] queue
  def create_imports(csv, queue = Bulwark::Queues::DEFAULT_PRIORITY)
    rows = Bulwark::StructuredCSV.parse(csv)
    rows.each do |row|
      digital_object_import = DigitalObjectImport.create(bulk_import: self, import_data: row)
      ProcessDigitalObjectImportJob.set(queue: queue).perform_later(digital_object_import)
    end
  end

  # Generate CSV for Bulk Import.
  def csv
    data = digital_object_imports.map(&:import_data)
    Bulwark::StructuredCSV.generate(data)
  end

  private

    # Determine if the related DO Imports are all complete (_not_ in progress or queued) and has at least one failed
    # @return [TrueClass, FalseClass]
    def imports_finished_with_failures?
      digital_object_imports.where(status: DigitalObjectImport::FAILED).exists? &&
        digital_object_imports.where(
          status: [DigitalObjectImport::QUEUED, DigitalObjectImport::IN_PROGRESS]
        ).blank?
    end
end
