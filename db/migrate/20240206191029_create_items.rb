class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :unique_identifier, null: false, index: { unique: true }
      t.text :published_json, limit: 16.megabytes - 1, null: false

      t.timestamps null: false
    end
  end
end
