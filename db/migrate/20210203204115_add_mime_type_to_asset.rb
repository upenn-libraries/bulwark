class AddMimeTypeToAsset < ActiveRecord::Migration
  def change
    add_column :assets, :mime_type, :string
  end
end
