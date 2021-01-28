class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.belongs_to :repo
      t.string :filename
      t.integer :size, limit: 8 # bigint
      t.text :original_file_location
      t.text :access_file_location
      t.text :preview_file_location
      t.timestamps null: false
    end
  end
end
