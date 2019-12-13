class AddDsaKeysToAccounts < ActiveRecord::Migration[5.2]
  def up
    rename_column :accounts, :public_key, :rsa_public_key
    rename_column :accounts, :private_key, :rsa_private_key

    add_column :accounts, :dsa_public_key, :text
    add_column :accounts, :dsa_private_key, :text

    Account.find_each do |account|
      next if account.dsa_private_key.present? ||
              account.dsa_public_key.present?

      account.send :generate_dsa_keys! # Private method
      account.save! validate: false
    end
  end

  def down
    rename_column :accounts, :rsa_public_key, :public_key
    rename_column :accounts, :rsa_private_key, :private_key

    remove_column :accounts, :dsa_public_key
    remove_column :accounts, :dsa_private_key
  end
end
