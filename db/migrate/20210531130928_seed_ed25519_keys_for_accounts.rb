class SeedEd25519KeysForAccounts < ActiveRecord::Migration[6.1]
  def change
    Account.find_each do |account|
      next if account.ed25519_private_key.present? ||
              account.ed25519_public_key.present?

      account.send(:generate_ed25519_keys!)
      account.save!(validate: false)
    end
  end
end
