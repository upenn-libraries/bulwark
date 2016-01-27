class RenameColumns < ActiveRecord::Migration
  def change
    rename_column :repos, :purl, :directory
    rename_column :repos, :prefix, :identifier

  end
end
