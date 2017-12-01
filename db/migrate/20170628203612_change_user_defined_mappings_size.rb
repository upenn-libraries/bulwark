class ChangeUserDefinedMappingsSize < ActiveRecord::Migration
  def change
    change_column :metadata_sources, :user_defined_mappings, :text, :limit => 4294967295
  end
end
