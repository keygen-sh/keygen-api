class AddSecretKeyToAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :accounts, :secret_key, :text

    Account.find_each do |account|
      next if account.secret_key.present?

      account.send :generate_secret_key! # Private method
      account.save! validate: false
    end
  end
end
