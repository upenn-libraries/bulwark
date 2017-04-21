class AddLastActionPerformedToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :last_action_performed, :string
  end
end
