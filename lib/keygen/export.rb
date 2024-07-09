# frozen_string_literal: true

module Keygen
  module Exportable
    CLASSES = Set.new

    def self.classes = CLASSES
    def self.included(klass)
      raise ArgumentError, "cannot be used outside of model (got #{klass.ancestors})" unless
        klass < ::ActiveRecord::Base

      CLASSES << klass
    end

    # FIXME(ezekg) Make this overrideable via .exports with: -> { ... } to support
    #              e.g. exporting a user's role since it isn't Accountable.
    def attributes_for_export
      attributes
    end
  end

  module Export
    extend self

    def export(account, to: StringIO.new, secret_key: nil)
      Exporter.new(account, secret_key:)
              .export(to:)
    end

    private

    class Exporter
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

        def secret_key_digest = OpenSSL::Digest::SHA256.digest(secret_key.to_s)
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

          iv + tag + ciphertext
        end
      end

      class Writer
        def initialize(io) = @io = io

        def to_io       = @io
        def write(data) = @io.write(data)

        def write_version
          version = [1].pack('C')

          write(version)
        end

        def write_chunk(data)
          bytesize = [data.bytesize].pack('Q>')

          write(bytesize)
          write(data)
        end
      end

      def initialize(account, secret_key: nil)
        @account    = account
        @serializer = Serializer.new(secret_key:)
      end

      def export(to: StringIO.new)
        writer = Writer.new(to)
        writer.write_version

        export_record(account.class.name, account.attributes_for_export, writer:)
        export_associations(writer:)

        writer.to_io
      end

      private

      attr_reader :account,
                  :serializer

      def export_record(class_name, attributes, writer:)
        serialized = serializer.serialize(class_name, attributes)

        writer.write_chunk(serialized)
      end

      def export_associations(writer:)
        Account.reflect_on_all_associations.each do |reflection|
          next unless exportable_reflection?(reflection)

          @account.association(reflection.name).scope.in_batches(of: 1_000) do |records|
            attributes = records.map(&:attributes_for_export)

            export_record(reflection.klass.name, attributes, writer:)
          end
        end
      end

      def exportable_reflection?(reflection)
        Keygen::Exportable.classes.include?(reflection.klass) &&
          !reflection.polymorphic? &&
          !reflection.union_of?
      end
    end
  end
end
