class AddXmlPreviewToMetadataBuilders < ActiveRecord::Migration
  def change
    add_column :metadata_builders, :xml_preview, :string
  end
end
