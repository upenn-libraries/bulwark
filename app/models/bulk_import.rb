# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  COMPLETED = 'completed'
  IN_PROGRESS = 'in progress'
  QUEUED = 'queued'

  has_many :digital_object_imports, dependent: :destroy
  belongs_to :created_by, class_name: User

  # kamanari config
  paginates_per 5
  max_paginates_per 100

  delegate :email, to: :created_by, prefix: true

  # Returns 'Completed', 'In Progress', 'Queued' depending on status of the
  # child import jobs. Completed means all jobs were either failed or were
  # successful. In progress if there are any jobs in progress. Queued if
  # all the jobs are queued.
  def status
    if digital_object_imports.blank?
      COMPLETED
    elsif digital_object_imports.any?(&:in_progress?)
      IN_PROGRESS
    elsif digital_object_imports.all?(&:queued?)
      QUEUED
    else
      COMPLETED
    end
  end

  def number_of_errors
    digital_object_imports.where(status: DigitalObjectImport::FAILED).count
  end

  # Returns Hash with validation errors. Errors are organized by row number. The
  # keys in the hash are the rows and the values are the errors correspoinding to
  # that row.
  def validation_errors(csv)
    validation_errors = {}
    rows = Bulwark::StructuredCSV.parse(csv)
    rows.each_with_index do |row, index|
      import = Bulwark::Import.new(created_by: created_by, **row.symbolize_keys)

      unless import.validate
        validation_errors["row #{index + 2}"] = import.errors
      end
    end
    validation_errors.blank? ? nil : validation_errors
  end

  def create_imports(csv)
    rows = Bulwark::StructuredCSV.parse(csv)
    rows.each do |row|
      digital_object_import = DigitalObjectImport.create(bulk_import: self, import_data: row)
      ProcessDigitalObjectImportJob.perform_later(digital_object_import)
    end
  end
end
