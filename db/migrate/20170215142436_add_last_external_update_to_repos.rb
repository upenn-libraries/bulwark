class AddLastExternalUpdateToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :last_external_update, :timestamp
  end
end
