class RemoveWorkingPathFromVersionControlAgents < ActiveRecord::Migration
  def change
    remove_column :version_control_agents, :working_path
  end
end
