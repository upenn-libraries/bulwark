class AddUniqueIdentifierToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :unique_identifier, :string
  end
end
