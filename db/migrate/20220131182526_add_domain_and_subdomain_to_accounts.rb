class AddDomainAndSubdomainToAccounts < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_column :accounts, :domain,    :string, null: true
    add_column :accounts, :subdomain, :string, null: true

    add_index :accounts, :domain,    unique: true, algorithm: :concurrently
    add_index :accounts, :subdomain, unique: true, algorithm: :concurrently
  end
end
