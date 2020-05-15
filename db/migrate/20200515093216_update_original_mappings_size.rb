class UpdateOriginalMappingsSize < ActiveRecord::Migration
    def change
      change_column :metadata_sources, :original_mappings, :text, :limit => 4294967295
    end
  end
  