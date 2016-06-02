class AddMetadataSourcesToMetadataBuilder < ActiveRecord::Migration
  def change
    add_reference :metadata_builders, :metadata_source, index: true, foreign_key: true
  end
end
