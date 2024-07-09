# frozen_string_literal: true

module Keygen
  module Import
    extend self

    def import(account, from:, secret_key: nil)
      Importer.new(account, secret_key:)
              .import(from:)
    end

    private

    class Importer
      def initialize(account, secret_key: nil)
        @account    = account
        @secret_key = secret_key
      end

      def import(from:)
        version = from.read(1).unpack1('C')

        case version
        when 1
          while prefix = from.read(8)
            process_chunk(prefix, from:)
          end
        else
          abort 'export version is unsupported'
        end
      rescue OpenSSL::Cipher::CipherError
        abort 'secret key is invalid'
      end

      private

      def decrypt(plaintext)
        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.decrypt

        key    = generate_key(@secret_key)
        reader = StringIO.new(plaintext)

        iv         = reader.read(12) # 96-bit
        tag        = reader.read(16) # 128-bit
        ciphertext = reader.read

        aes.key       = key
        aes.iv        = iv
        aes.auth_tag  = tag
        aes.auth_data = ''

        aes.update(ciphertext) + aes.final
      end

      def generate_key(secret_key)
        OpenSSL::Digest::SHA256.digest(secret_key.to_s)
      end

      def process_chunk(chunk_prefix, from:)
        chunk_size  = chunk_prefix.unpack1('Q>')
        chunk       = from.read(chunk_size)
        encrypted   = Zlib.inflate(chunk)
        unencrypted = decrypt(encrypted)
        unpacked    = MessagePack.unpack(unencrypted)

        import_records(unpacked)
      end

      def import_records(unpacked)
        class_name, attributes = unpacked

        # TODO(ezekg) import into db
        puts(class_name => attributes)
      end
      alias :import_record :import_records
    end
  end
end
