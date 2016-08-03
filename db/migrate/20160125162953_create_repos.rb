class CreateRepos < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.string :human_readable_name
      t.string :purl
      t.string :description
      t.timestamps null: false
    end
  end
end
