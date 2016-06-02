class CreateMetadataSources < ActiveRecord::Migration
  def change
    create_table :metadata_sources do |t|
      t.string :path
      t.string :view_type, :default => "horizontal"
      t.integer :num_objects, :default => 1
      t.integer :x_start, :default => 1
      t.integer :y_start, :default => 1
      t.integer :x_stop, :default => 1
      t.integer :y_stop, :default => 1
      t.text :original_mappings
      t.string :root_element
      t.string :parent_element
      t.text :user_defined_mappings
      t.text :children
      t.timestamps null: false
    end
  end
end
