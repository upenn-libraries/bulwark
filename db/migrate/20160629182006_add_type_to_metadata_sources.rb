class AddTypeToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :source_type, :string
  end
end
