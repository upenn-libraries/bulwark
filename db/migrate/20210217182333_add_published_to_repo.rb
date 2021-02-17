class AddPublishedToRepo < ActiveRecord::Migration
  def change
    add_column :repos, :published, :boolean, default: false
  end
end
