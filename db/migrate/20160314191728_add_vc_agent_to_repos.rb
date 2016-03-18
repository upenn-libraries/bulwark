class AddVcAgentToRepos < ActiveRecord::Migration
  def change
    add_reference :repos, :version_control_agent, index: true, foreign_key: true
  end
end
