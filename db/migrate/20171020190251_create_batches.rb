class CreateBatches < ActiveRecord::Migration
  def change
    create_table :batches do |t|
      t.string :queue_list
      t.string :directive_names
      t.string :email
      t.timestamp :start
      t.timestamp :end
      t.string :status

      t.timestamps null: false
    end
  end
end
