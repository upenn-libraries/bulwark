class CreateManifests < ActiveRecord::Migration
  def change
    create_table :manifests do |t|
      t.string :name
      t.text :content, :limit => 4294967295
      t.text :validation_problems, :limit => 4294967295
      t.string :owner
      t.string :steps
      t.string :last_action_performed

      t.timestamps null: false
    end
  end
end
