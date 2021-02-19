class AddRemoteLocationToMetadataSource < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :remote_location, :text
  end
end
