class AddHasThumbnailToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :has_thumbnail, :boolean, default: false
  end
end
