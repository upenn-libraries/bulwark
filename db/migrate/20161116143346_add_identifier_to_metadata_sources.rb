class AddIdentifierToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :identifier, :string
  end
end
