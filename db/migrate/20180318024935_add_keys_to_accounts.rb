class AddKeysToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :public_key, :text
    add_column :accounts, :private_key, :text
  end

  def up
    Account.find_each do |account|
      next if account.private_key.present? ||
              account.public_key.present?

      account.generate_keys!
    end
  end
end
