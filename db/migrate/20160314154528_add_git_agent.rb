class AddGitAgent < ActiveRecord::Migration
  def change
    add_column :repos, :git_agent, :string
  end
end
