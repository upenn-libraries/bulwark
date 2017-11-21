class AddQueuedToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :queued, :string
  end
end
