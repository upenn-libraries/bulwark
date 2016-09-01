class AddProblemFilesToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :problem_files, :string
  end
end
