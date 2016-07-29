class AddLastSettingsUpdatedToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :last_settings_updated, :timestamp
  end
end
