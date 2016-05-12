class AddMetadataBuildersModel < ActiveRecord::Migration
  def change
    create_table :metadata_builders do |t|
      t.string :parent_repo
      t.string :source
      t.text :source_type
      t.text :source_num_objects
      t.text :source_coordinates
      t.string :preserve
      t.string :nested_relationships
      t.text :source_mappings
      t.text :field_mappings
      t.timestamps null: false
    end
  end
end
