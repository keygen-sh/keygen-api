class RenameSubdomainAndNameForAccounts < ActiveRecord::Migration[5.0]
  def change
    rename_column :accounts, :name, :company
    rename_column :accounts, :subdomain, :name
  end
end
