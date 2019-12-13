class AddEcdsaKeysToAccounts < ActiveRecord::Migration[5.2]
  def up
    add_column :accounts, :ecdsa_public_key, :text
    add_column :accounts, :ecdsa_private_key, :text

    Account.find_each do |account|
      next if account.ecdsa_private_key.present? ||
              account.ecdsa_public_key.present?

      account.send :generate_ecdsa_keys! # Private method
      account.save! validate: false
    end
  end

  def down
    remove_column :accounts, :ecdsa_public_key
    remove_column :accounts, :ecdsa_private_key
  end
end
