class AddMetadataBuildersModel < ActiveRecord::Migration
  def change
    create_table :metadata_builders do |t|
      t.string :parent_repo
      t.string :source
      t.text :source_mappings
      t.text :field_mappings
      t.text :xml
      t.timestamps null: false
    end
  end
end
