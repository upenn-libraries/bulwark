class AddGeneratedMetadataFilesToMetadataBuilder < ActiveRecord::Migration
  def change
    add_column :metadata_builders, :generated_metadata_files, :text
  end
end
