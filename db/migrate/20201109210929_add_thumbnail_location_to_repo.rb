class AddThumbnailLocationToRepo < ActiveRecord::Migration
  def change
    add_column :repos, :thumbnail_location, :text

  end
end
