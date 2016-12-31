class AddJobActivityToUsers < ActiveRecord::Migration
  def change
    add_column :users, :job_activity, :text, :limit => 4294967295
  end
end
