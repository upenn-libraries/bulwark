class AddNewFormatColumnToRepo < ActiveRecord::Migration
  def change
    # Adding this temporary field to keep track of repos created in new format.
    # Once everything gets migrated over we are can remove this field.
    add_column :repos, :new_format, :boolean, default: false
  end
end
