# frozen_string_literal: true

desc 'encrypt account private keys'
task encrypt_account_private_keys: :environment do
  Account.find_each do |account|
    next if
      account.encrypted_attribute?(:ed25519_private_key) ||
      account.encrypted_attribute?(:private_key) ||
      account.encrypted_attribute?(:secret_key)

    account.encrypt
    account.clear_cache!

    sleep 0.1
  end
end
