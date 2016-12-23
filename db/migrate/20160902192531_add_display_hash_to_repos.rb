class AddDisplayHashToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :images_to_render, :text, :limit => 4294967295
  end
end
