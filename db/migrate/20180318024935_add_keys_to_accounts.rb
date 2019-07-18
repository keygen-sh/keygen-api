# frozen_string_literal: true

class AddKeysToAccounts < ActiveRecord::Migration[5.0]
  def up
    add_column :accounts, :public_key, :text
    add_column :accounts, :private_key, :text

    Account.find_each do |account|
      next if account.private_key.present? ||
              account.public_key.present?

      account.send :generate_keys! # Private method
      account.save! validate: false
    end
  end

  def down
    remove_column :accounts, :public_key
    remove_column :accounts, :private_key
  end
end
