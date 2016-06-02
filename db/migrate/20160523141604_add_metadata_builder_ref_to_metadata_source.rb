class AddMetadataBuilderRefToMetadataSource < ActiveRecord::Migration
  def change
    add_reference :metadata_sources, :metadata_builder, index: true, foreign_key: true
  end
end
