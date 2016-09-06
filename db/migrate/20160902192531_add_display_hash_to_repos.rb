class AddDisplayHashToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :images_to_render, :string
  end
end
