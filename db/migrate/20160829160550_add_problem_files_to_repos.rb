class AddProblemFilesToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :problem_files, :text, :limit => 4294967295
  end
end
