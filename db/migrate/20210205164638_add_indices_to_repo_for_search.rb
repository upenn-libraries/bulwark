class AddIndicesToRepoForSearch < ActiveRecord::Migration
  def change
    add_index :repos, :human_readable_name
    add_index :repos, :unique_identifier
  end
end
