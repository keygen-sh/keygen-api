# frozen_string_literal: true

namespace :keygen do
  desc 'Import data into a Keygen account'
  task :import, %i[account_id secret_key] => %i[silence environment] do |_, args|
    def getn(n) = STDIN.read(n)
    def decrypt(plaintext, secret_key:)
      aes = OpenSSL::Cipher::AES256.new(:GCM)
      aes.decrypt

      key         = OpenSSL::Digest::SHA256.digest(secret_key)
      reader      = StringIO.new(plaintext)
      iv          = reader.read(12) # 96-bit
      tag         = reader.read(16) # 128-bit
      ciphertext  = reader.read

      aes.key = key
      aes.iv  = iv

      aes.auth_tag  = tag
      aes.auth_data = ''

      aes.update(ciphertext) + aes.final
    end

    ActiveRecord::Base.logger.silence do
      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      secret_key = args[:secret_key]

      account = Account.find(account_id)
      version = getn(1).unpack1('C')

      puts(version:)

      while chunk_prefix = getn(8)
        chunk_size  = chunk_prefix.unpack1('Q>')
        chunk       = getn(chunk_size)
        encrypted   = Zlib.inflate(chunk)
        unencrypted = decrypt(encrypted, secret_key:)
        unpacked    = MessagePack.unpack(unencrypted)

        # TODO(ezekg) import into db
        class_name, attributes = unpacked

        puts(class_name => attributes)
      end
    end
  rescue OpenSSL::Cipher::CipherError
    abort 'secret key is invalid'
  end
end
