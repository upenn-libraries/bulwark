class AddEndpointToRepos < ActiveRecord::Migration
  def change
    add_reference :repos, :endpoint, index: true, foreign_key: true
  end
end
