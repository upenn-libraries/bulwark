class AddRepoRefToEndpoints < ActiveRecord::Migration
  def change
    add_reference :endpoints, :repo, index: true, foreign_key: true
  end
end
