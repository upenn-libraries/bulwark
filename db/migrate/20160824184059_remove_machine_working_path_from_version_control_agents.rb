class RemoveMachineWorkingPathFromVersionControlAgents < ActiveRecord::Migration
  def change
    remove_column :version_control_agents, :machine_working_path
  end
end
