class CreateAssets < ActiveRecord::Migration
  def change
    create_table :assets do |t|
      t.belongs_to :repo
      t.string :filename
      t.integer :size, limit: 8 # bigint
      t.text :original_file_location
      t.text :access_file_location
      t.text :thumbnail_file_location
      t.timestamps null: false

      t.index [:filename, :repo_id], unique: true
    end
  end
end
