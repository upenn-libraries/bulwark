class AddMetadataBuildersModel < ActiveRecord::Migration
  def change
    create_table :metadata_builders do |t|
      t.string :parent_repo
      t.string :source
      t.string :preserve
      t.timestamps null: false
    end
  end
end
