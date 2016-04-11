class AddColumns < ActiveRecord::Migration
  def change
    add_column :repos, :metadata_subdirectory, :string
    add_column :repos, :assets_subdirectory, :string
    add_column :repos, :metadata_filename, :string
    add_column :repos, :file_extensions, :string
    add_column :repos, :ingested, :string

  end
end
