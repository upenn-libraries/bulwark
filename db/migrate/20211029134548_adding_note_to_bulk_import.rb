class AddingNoteToBulkImport < ActiveRecord::Migration
  def change
    add_column :bulk_imports, :note, :text
  end
end
