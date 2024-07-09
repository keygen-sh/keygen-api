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
      def initialize(account, secret_key: nil)
        @account    = account
        @secret_key = secret_key
      end

      def export(to:)
        eager_load!

        version = [1].pack('C')
        to.write(version)

        export_record(Account.name, @account.attributes_for_export, to:)
        export_associations(to:)

        to
      end

      private

      def eager_load! = Zeitwerk::Loader.eager_load_all

      def encrypt(plaintext)
        aes = OpenSSL::Cipher::AES256.new(:GCM)
        aes.encrypt

        key = generate_key(@secret_key)
        iv  = aes.random_iv

        aes.key = key
        aes.iv  = iv

        ciphertext = aes.update(plaintext) + aes.final
        tag        = aes.auth_tag

        iv + tag + ciphertext
      end

      def generate_key(secret_key)
        OpenSSL::Digest::SHA256.digest(secret_key.to_s)
      end

      def export_records(class_name, attributes, to:)
        packed     = MessagePack.pack([class_name, attributes])
        encrypted  = encrypt(packed)
        compressed = Zlib.deflate(encrypted, Zlib::BEST_COMPRESSION)
        bytesize   = [compressed.bytesize].pack('Q>')

        to.write(bytesize + compressed)
      end
      alias :export_record :export_records

      def export_associations(to:)
        Account.reflect_on_all_associations.each do |reflection|
          next unless exportable?(reflection)

          @account.association(reflection.name).scope.in_batches(of: 1_000) do |records|
            attributes = records.map(&:attributes_for_export)

            export_records(reflection.klass.name, attributes, to:)
          end
        end
      end

      def exportable?(reflection)
        Keygen::Exportable.classes.include?(reflection.klass) &&
        !reflection.polymorphic? &&
        !reflection.union_of?
      end
    end
  end
end
