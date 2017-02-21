class AddFetchMethodToEndpoints < ActiveRecord::Migration
  def change
    add_column :endpoints, :fetch_method, :string
  end
end
