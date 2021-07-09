class CreateAlertMessages < ActiveRecord::Migration
  def up
    create_table :alert_messages do |t|
      t.boolean :active, default: false
      t.string :message
      t.string :level
      t.string :location
    end

    AlertMessage.create! [{ location: 'header' }, { location: 'home'}]
  end

  def down
    drop_table :alert_messages
  end
end
