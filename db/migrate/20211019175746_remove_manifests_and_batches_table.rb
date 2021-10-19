class RemoveManifestsAndBatchesTable < ActiveRecord::Migration
  def change
    drop_table :manifests
    drop_table :batches
  end
end
