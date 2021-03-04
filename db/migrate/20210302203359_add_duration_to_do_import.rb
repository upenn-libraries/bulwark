class AddDurationToDoImport < ActiveRecord::Migration
  def change
    add_column :digital_object_imports, :duration, :integer
  end
end
