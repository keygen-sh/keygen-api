# frozen_string_literal: true

namespace :keygen do
  desc 'Export data from a Keygen account'
  task :export, %i[account_id secret_key] => %i[silence environment] do |_, args|
    def encrypt(plaintext, secret_key:)
      aes = OpenSSL::Cipher::AES256.new(:GCM)
      aes.encrypt

      key = OpenSSL::Digest::SHA256.digest(secret_key)
      iv  = aes.random_iv

      aes.key = key
      aes.iv  = iv

      ciphertext = aes.update(plaintext) + aes.final
      tag        = aes.auth_tag

      iv + tag + ciphertext
    end

    ActiveRecord::Base.logger.silence do
      Zeitwerk::Loader.eager_load_all

      account_id = args[:account_id] || ENV.fetch('KEYGEN_ACCOUNT_ID')
      secret_key = args[:secret_key]

      account = Account.find(account_id)
      version = [1].pack('C')

      print(version)

      # Our format consists of a preceding 4-byte integer indicating the
      # size of the subsequent chunk. During import, we read the first
      # 4 bytes of the input for size=n then read the entire chunk of
      # size n, and then repeat for the next chunk.
      packed     = MessagePack.pack([Account.name, account.attributes_for_export])
      encrypted  = encrypt(packed, secret_key:)
      compressed = Zlib.deflate(encrypted, Zlib::BEST_COMPRESSION)
      bytesize   = [compressed.bytesize].pack('Q>')

      print(bytesize)
      print(compressed)

      Account.reflect_on_all_associations.each do |reflection|
        next unless
          Keygen::Exportable.classes.include?(reflection.klass)

        next if
          reflection.polymorphic? || reflection.union_of?

        association = account.association(reflection.name)
        scope       = association.scope

        scope.in_batches(of: 1_000) do |records|
          attrs = []

          records.each do |record|
            attrs << record.attributes_for_export
          end

          packed     = MessagePack.pack([reflection.klass.name, attrs])
          encrypted  = encrypt(packed, secret_key:)
          compressed = Zlib.deflate(encrypted, Zlib::BEST_COMPRESSION)
          bytesize   = [compressed.bytesize].pack('Q>')

          print(bytesize)
          print(compressed)
        end
      end
    end
  end
end
