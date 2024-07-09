# frozen_string_literal: true

module Keygen
  module Import
    extend self

    def import(from:, secret_key: nil)
      reader  = Reader.new(from)
      version = reader.read_version

      importer_class = importer_class_for(version:)
      importer       = importer_class.new(secret_key:)

      importer.import(reader:)
    rescue OpenSSL::Cipher::CipherError
      raise 'secret key is invalid'
    end

    private

    def importer_class_for(version:)
      case version
      when 1
        V1::Importer
      else
        raise "Unsupported import version: #{version}"
      end
    end

    class Reader
      def initialize(io) = @io = io
      def read(n)        = @io.read(n)
      def read_version   = read(1).unpack1('C') # first byte is the version
      def read_chunk     = raise NotImplementedError
    end

    module V1
      class Importer
        VERSION = 1

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

          def secret_key_digest = OpenSSL::Digest::SHA256.digest(secret_key.to_s)
          def secret_key?       = secret_key.present?

          def decompress(data) = Zlib.inflate(data)
          def unpack(data)     = MessagePack.unpack(data)
        end

        class Reader < Reader
          def read_chunk_size = read(8)&.unpack1('Q>') || 0
          def read_chunk
            chunk_size = read_chunk_size
            return if chunk_size.zero?

            read(chunk_size)
          end
        end

        def initialize(secret_key: nil)
          @deserializer = Deserializer.new(secret_key:)
        end

        def import(reader:)
          v1_reader = Reader.new(reader)

          while chunk = v1_reader.read_chunk
            process_chunk(chunk)
          end
        end

        private

        attr_reader :deserializer

        def process_chunk(chunk)
          class_name, attributes = deserializer.deserialize(chunk)

          import_records(class_name, attributes)
        end

        def import_records(class_name, attributes)
          klass = class_name.constantize

          klass.insert_all(attributes)
        end
      end
    end
  end
end
