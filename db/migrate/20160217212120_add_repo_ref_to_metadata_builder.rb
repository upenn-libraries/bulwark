class AddRepoRefToMetadataBuilder < ActiveRecord::Migration
  def change
    add_reference :metadata_builders, :repo, index: true, foreign_key: true
  end
end
