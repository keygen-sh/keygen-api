# frozen_string_literal: true

module Keygen
  module Import
    module V1
      class Deserializer
        TAG_BYTE_SIZE = 16 # 128-bit
        IV_BYTE_SIZE  = 12 # 96-bit

        def initialize(secret_key: nil)
          @secret_key = secret_key
        end

        def deserialize(data)
          decompressed = decompress(data)
          unencrypted  = decrypt(decompressed)

          unpack(unencrypted)
        end

        private

        attr_reader :secret_key

        def decrypt(data)
          return data unless secret_key?

          aes = OpenSSL::Cipher::AES256.new(:GCM)
          aes.decrypt

          reader = StringIO.new(data)
          key    = secret_key_digest

          tag        = reader.read(TAG_BYTE_SIZE)
          iv         = reader.read(IV_BYTE_SIZE)
          ciphertext = reader.read

          aes.auth_tag  = tag
          aes.iv        = iv
          aes.key       = key
          aes.auth_data = ''

          aes.update(ciphertext) + aes.final
        end

        def secret_key_digest = OpenSSL::Digest::SHA256.digest(secret_key)
        def secret_key?       = secret_key.present?

        def decompress(data) = Zlib.inflate(data)
        def unpack(data)     = MessagePack.unpack(data)
      end
    end
  end
end
