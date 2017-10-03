class AddQueuedToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :queued, :boolean
  end
end
