class VersionControlAgents < ActiveRecord::Migration
  def change
    create_table :version_control_agents do |t|
      t.string :vc_type
      t.string :remote_path
      t.string :working_path
      t.references :repo, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
