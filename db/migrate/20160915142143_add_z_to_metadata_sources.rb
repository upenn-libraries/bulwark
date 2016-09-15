class AddZToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :z, :integer, :default => 1
  end
end
