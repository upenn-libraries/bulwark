# frozen_string_literal: true

class BulkImport < ActiveRecord::Base
  has_many :digital_object_imports, dependent: :destroy
  belongs_to :created_by, class_name: User

  # kamanari config
  paginates_per 5
  max_paginates_per 100

  delegate :email, to: :created_by, prefix: true

  # Returns Hash with validation errors. Errors are organized by row number. The
  # keys in the hash are the rows and the values are the errors correspoinding to
  # that row.
  def validation_errors(csv)
    validation_errors = {}
    rows = Bulwark::StructuredCSV.parse(csv)
    rows.each_with_index do |row, index|
      import = Bulwark::Import.new(
        descriptive_metadata: row['metadata'],
        structural_metadata: row['structural'],
        assets: row['assets'],
        unique_identifier: row['unique_identifier'],
        directive: row['directive'],
        type: row['action'],
        created_by: created_by
      )
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
