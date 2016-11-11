class AddInputSourceToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :input_source, :string
  end
end
