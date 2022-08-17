class AddCnameToAccounts < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_column :accounts, :cname, :string, null: true

    add_index :accounts, :cname, unique: true, algorithm: :concurrently
  end
end
