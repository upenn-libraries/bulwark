class AddStepsToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :steps, :string
  end
end
