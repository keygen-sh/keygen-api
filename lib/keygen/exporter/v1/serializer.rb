# frozen_string_literal: true

module Keygen
  module Exporter
    module V1
      class Serializer
        def initialize(secret_key: nil)
          @secret_key = secret_key
        end

        def serialize(class_name, attributes)
          packed    = pack([class_name, attributes])
          encrypted = encrypt(packed)

          compress(encrypted)
        end

        private

        attr_reader :secret_key

        def secret_key_digest = OpenSSL::Digest::SHA256.digest(secret_key)
        def secret_key?       = secret_key.present?

        def compress(data) = Zlib.deflate(data, Zlib::BEST_COMPRESSION)
        def pack(data)     = MessagePack.pack(data)
        def encrypt(plaintext)
          return plaintext unless secret_key?

          aes = OpenSSL::Cipher::AES256.new(:GCM)
          aes.encrypt

          key = secret_key_digest
          iv  = aes.random_iv

          aes.key = key
          aes.iv  = iv

          ciphertext = aes.update(plaintext) + aes.final
          tag        = aes.auth_tag

          tag + iv + ciphertext
        end
      end
    end
  end
end
