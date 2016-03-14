class VersionControlAgents < ActiveRecord::Migration
  def change
    create_table :version_control_agents do |t|
      t.string :type
      t.references :repo, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
