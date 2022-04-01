# frozen_string_literal: true

desc 'encrypt account private keys'
task encrypt_account_private_keys: :environment do
  Account.find_each do |account|
    next if
      account.encrypted_attribute?(:private_key)

    account.encrypt
  end
end
