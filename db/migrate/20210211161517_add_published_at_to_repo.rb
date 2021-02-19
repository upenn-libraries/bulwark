class AddPublishedAtToRepo < ActiveRecord::Migration
  def change
    add_column :repos, :first_published_at, :datetime
    add_column :repos, :last_published_at, :datetime
  end
end
