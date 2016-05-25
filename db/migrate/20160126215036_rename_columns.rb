class RenameColumns < ActiveRecord::Migration
  def change
    rename_column :repos, :purl, :directory
  end
end
