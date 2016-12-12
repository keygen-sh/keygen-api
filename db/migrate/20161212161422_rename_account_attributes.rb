class RenameAccountAttributes < ActiveRecord::Migration[5.0]
  def change
    rename_column :accounts, :name, :slug
    rename_column :accounts, :company, :name
  end
end
