class AddXmlPreviewToMetadataBuilders < ActiveRecord::Migration
  def change
    add_column :metadata_builders, :xml_preview, :text, :limit => 4294967295
  end
end
