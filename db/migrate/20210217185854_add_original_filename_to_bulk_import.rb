class AddOriginalFilenameToBulkImport < ActiveRecord::Migration
  def change
    add_column :bulk_imports, :original_filename, :text
  end
end
