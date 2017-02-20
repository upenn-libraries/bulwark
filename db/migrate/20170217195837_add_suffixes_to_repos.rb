class AddSuffixesToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :endpoint_suffix, :string, :default => ''
    add_column :repos, :metadata_suffix, :string, :default => ''
    add_column :repos, :assets_suffix, :string, :default => ''
  end
end
