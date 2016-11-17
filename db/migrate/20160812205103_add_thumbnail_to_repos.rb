class AddThumbnailToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :thumbnail, :string
  end
end
