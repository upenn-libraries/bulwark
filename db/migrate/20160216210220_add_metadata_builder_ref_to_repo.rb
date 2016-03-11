class AddMetadataBuilderRefToRepo < ActiveRecord::Migration
  def change
    add_reference :repos, :metadata_builder, index: true, foreign_key: true
  end
end
