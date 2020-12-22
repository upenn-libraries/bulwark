# frozen_string_literal: true

class CreateDigitalObjectImports < ActiveRecord::Migration
  def change
    create_table :digital_object_imports do |t|
      t.references :bulk_import
      t.string :status
      t.text :process_errors
      # give extra room for item_data hash
      t.text :import_data, limit: 16.megabytes - 1
      t.timestamps null: false
    end
  end
end
