class AddLastXmlGeneratedToMetadataBuilders < ActiveRecord::Migration
  def change
    add_column :metadata_builders, :last_xml_generated, :timestamp
  end
end
