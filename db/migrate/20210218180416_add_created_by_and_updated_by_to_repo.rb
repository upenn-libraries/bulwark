class AddCreatedByAndUpdatedByToRepo < ActiveRecord::Migration
  def change
    add_reference :repos, :created_by
    add_foreign_key :repos, :users, column: :created_by_id
    add_reference :repos, :updated_by
    add_foreign_key :repos, :users, column: :updated_by_id
  end
end
