class AddColumns < ActiveRecord::Migration
  def change
    add_column :repos, :metadata_subdirectory, :string
    add_column :repos, :assets_subdirectory, :string
    add_column :repos, :derivatives_subdirectory, :string
    add_column :repos, :file_extensions, :string
    add_column :repos, :metadata_source_extensions, :string
    add_column :repos, :ingested, :boolean
    add_column :repos, :preservation_filename, :string
    add_column :repos, :review_status, :string
  end
end
