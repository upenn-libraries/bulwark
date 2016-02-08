class AddMdSources < ActiveRecord::Migration
  def change
    add_column :repos, :metadata_sources, :text
  end
end
