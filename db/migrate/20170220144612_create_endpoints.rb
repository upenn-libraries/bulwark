class CreateEndpoints < ActiveRecord::Migration
  def change
    create_table :endpoints do |t|
      t.string :source
      t.string :destination
      t.string :content_type
      t.string :protocol

      t.timestamps null: false
    end
  end
end
