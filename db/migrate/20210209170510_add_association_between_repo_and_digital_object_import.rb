class AddAssociationBetweenRepoAndDigitalObjectImport < ActiveRecord::Migration
  def change
    add_reference :digital_object_imports, :repo, foreign_key: true
  end
end
