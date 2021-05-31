class AddEd25519KeysToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :ed25519_private_key, :text
    add_column :accounts, :ed25519_public_key, :text
  end
end
