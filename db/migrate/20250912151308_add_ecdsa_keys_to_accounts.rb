class AddEcdsaKeysToAccounts < ActiveRecord::Migration[7.2]
  verbose!

  def change
    add_column :accounts, :ecdsa_private_key, :text
    add_column :accounts, :ecdsa_public_key, :text
  end
end
