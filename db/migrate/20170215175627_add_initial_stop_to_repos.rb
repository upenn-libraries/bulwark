class AddInitialStopToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :initial_stop, :string
  end
end
