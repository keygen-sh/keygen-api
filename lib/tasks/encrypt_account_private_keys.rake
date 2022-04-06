# frozen_string_literal: true

desc 'encrypt account private keys'
task encrypt_account_private_keys: :environment do
  Account.find_each do |account|
    ed25519_key_encrypted = account.encrypted_attribute?(:ed25519_private_key)
    rsa_key_encrypted     = account.encrypted_attribute?(:private_key)
    secret_key_encrypted  = account.encrypted_attribute?(:secret_key)

    # Check if the account is already encrypted
    if ed25519_key_encrypted || rsa_key_encrypted || secret_key_encrypted
      puts "[encrypt_account_private_keys] Account already encrypted: id=#{account.id} ed25519_key=#{ed25519_key_encrypted} rsa_key=#{rsa_key_encrypted} secret_key=#{secret_key_encrypted}"
      puts "[encrypt_account_private_keys] Skipping..."

      next
    end

    puts "[encrypt_account_private_keys] Encrypting account: id=#{account.id}"

    account.encrypt

    puts "[encrypt_account_private_keys] Clearing cache..."

    account.clear_cache!

    sleep 0.1
  end

  puts "[encrypt_account_private_keys] Done"
end
