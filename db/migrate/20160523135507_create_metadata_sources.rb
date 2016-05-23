class CreateMetadataSources < ActiveRecord::Migration
  def change
    create_table :metadata_sources do |t|
      t.string :path
      t.string :type
      t.integer :num_objects
      t.integer :x_start
      t.integer :y_start
      t.integer :x_stop
      t.integer :y_stop
      t.text :original_mappings
      t.text :user_defined_mappings
      t.timestamps null: false
    end
  end
end
