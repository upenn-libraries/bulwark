class AddLastFileChecksToMetadataBuilders < ActiveRecord::Migration
  def change
    add_column :metadata_builders, :last_file_checks, :timestamp
  end
end
