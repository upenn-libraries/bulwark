class AddFileFieldToMetadataSources < ActiveRecord::Migration
  def change
    add_column :metadata_sources, :file_field, :string
  end
end
