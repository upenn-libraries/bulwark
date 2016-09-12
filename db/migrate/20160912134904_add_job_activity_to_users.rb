class AddJobActivityToUsers < ActiveRecord::Migration
  def change
    add_column :users, :job_activity, :string
  end
end
