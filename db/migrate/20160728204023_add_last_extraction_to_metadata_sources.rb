class AddLastExtractionToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :last_extraction, :timestamp
  end
end
