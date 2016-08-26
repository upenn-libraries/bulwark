class AddMachineWorkingPathToVersionControlAgents < ActiveRecord::Migration
  def change
    add_column :version_control_agents, :machine_working_path, :string
  end
end
