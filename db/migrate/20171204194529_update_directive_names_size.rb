class UpdateDirectiveNamesSize < ActiveRecord::Migration
  def change
    change_column :batches, :queue_list, :text, :limit => 4294967295
    change_column :batches, :directive_names, :text, :limit => 4294967295
  end
end
