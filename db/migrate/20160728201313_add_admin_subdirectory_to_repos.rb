class AddAdminSubdirectoryToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :admin_subdirectory, :string
  end
end
