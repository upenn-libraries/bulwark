class AddAdminSubdirectoryToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :admin_subdirectory, :String
  end
end
