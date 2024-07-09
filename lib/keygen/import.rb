# frozen_string_literal: true

module Keygen
  module Import
    extend self

    def import(account, from:, secret_key: nil)
      reader  = Reader.new(from)
      version = reader.read_version

      importer_class = importer_class_for(version:)
      importer       = importer_class.new(account, secret_key:)

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
      def initialize(io)
        @io = io
      end

      def read(bytes)
        @io.read(bytes)
      end

      def read_version
        read(1).unpack1('C')
      end

      def read_chunk_size
        chunk_size_prefix = read(8)
        return if chunk_size_prefix.nil?

        chunk_size_prefix.unpack1('Q>')
      end
    end

    module V1
      class Importer
        class Deserializer
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

            iv         = reader.read(12) # 96-bit
            tag        = reader.read(16) # 128-bit
            ciphertext = reader.read

            aes.key       = key
            aes.iv        = iv
            aes.auth_tag  = tag
            aes.auth_data = ''

            aes.update(ciphertext) + aes.final
          end

          def secret_key_digest = OpenSSL::Digest::SHA256.digest(secret_key.to_s)
          def secret_key?       = secret_key.present?

          def decompress(data) = Zlib.inflate(data)
          def unpack(data)     = MessagePack.unpack(data)
        end

        def initialize(account, secret_key: nil)
          @account      = account
          @deserializer = Deserializer.new(secret_key:)
        end

        def import(reader:)
          while chunk_size = reader.read_chunk_size
            process_chunk(chunk_size, reader)
          end
        end

        private

        attr_reader :account, :deserializer

        def process_chunk(chunk_size, reader)
          chunk    = reader.read(chunk_size)
          unpacked = deserializer.deserialize(chunk)

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
end
