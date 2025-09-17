class SeedEcdsaKeysForAccounts < ActiveRecord::Migration[7.2]
  # NB(ezekg) migration is intentionally not verbose! to avoid logging keys

  def change
    Account.where(ecdsa_private_key: nil, ecdsa_public_key: nil).find_each do |account|
      account.send(:generate_ecdsa_keys!) # private
      account.save!(
        validate: false,
        touch: false,
      )
    end
  end
end
