class CreateAlertMessages < ActiveRecord::Migration
  def change
    create_table :alert_messages do |t|
      t.boolean :active, default: false
      t.datetime :display_on
      t.datetime :display_until
      t.string :message
      t.string :level
      t.string :location
      t.timestamps null: false
    end
  end
end
