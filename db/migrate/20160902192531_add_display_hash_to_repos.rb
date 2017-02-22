class AddDisplayHashToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :images_to_render, :text, :limit => 4294967295
    add_column :repos, :file_display_attributes, :text, :limit => 4294967295
  end
end
