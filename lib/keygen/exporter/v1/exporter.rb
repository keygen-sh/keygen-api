# frozen_string_literal: true

require 'digest'

require_relative 'serializer'
require_relative 'writer'

module Keygen
  module Exporter
    module V1
      ##
      # The export format consists of:
      #
      #   1. A leading byte indicating the version of the export format. Right
      #      now this is always 1, but can be used in the future if we need
      #      to make changes to the export format.
      #   2. A series of chunks, each prefixed by an 8-byte integer, indicating
      #      the size of the chunk. Each chunk represents packed, optionally
      #      encrypted, and compressed data.
      #
      # Chunks are represented with the following structure:
      #
      #   - 8 bytes: size of the chunk data.
      #   - n bytes: the chunk data.
      #
      # Chunk data consists of a serialized array of:
      #
      #   - A class name, representing the shared class of the packed records.
      #   - An array of attribute hashes, representing individual records.
      #
      # Note on serialization:
      #
      #   - Records are converted into a hash via #attributes_for_export.
      #   - Chunked and packed with MessagePack.
      #   - Encrypted with AES-256-GCM, if a secret key is provided.
      #   - Compressed with zlib.
      #
      # Note on encryption:
      #
      #   - Each chunk is encrypted individually so that the export can be
      #     piped, e.g. to stdout or a file, with a low memory footprint.
      #
      # Note on order:
      #
      #   - The first chunk will always be the exported account.
      #   - The next chunks will be batches of associations. Right now,
      #     we export in batches of 1,000.
      #
      # Example export:
      #
      #   <version><chunk_size><chunk_data>[<chunk_size><chunk_data>...]
      #       |          |           |            |           |
      #     1 byte    8 bytes     n bytes      8 bytes     n bytes
      #
      # Example chunk:
      #
      #   ['License', [{ ... }, { ... }, ...]]
      #        |          |        |
      #      class      attrs    attrs
      #
      class Exporter
        BATCH_SIZE = 1_000

        def initialize(account, secret_key: nil)
          @account    = account
          @serializer = Serializer.new(secret_key:)
        end

        def export(to: StringIO.new, digest: Digest::SHA256.new)
          writer = Writer.new(to, digest:)
          writer.write_version

          export_record(account.class.name, account.attributes_for_export, writer:)
          export_associations(account, writer:)

          writer.to_io
        end

        private

        attr_reader :account, :serializer

        def export_records(class_name, attributes, writer:)
          serialized = serializer.serialize(class_name, attributes)

          writer.write_chunk(serialized)
        end

        def export_record(class_name, attributes, writer:)
          export_records(class_name, [attributes], writer:)
        end

        def export_associations(owner, writer:)
          owner.class.reflect_on_all_associations.each do |reflection|
            next unless portable_reflection?(reflection)

            association = owner.association(reflection.name)
            scope       = association.scope

            scope.in_batches(of: BATCH_SIZE) do |records|
              attributes = records.map(&:attributes_for_export)

              export_records(reflection.klass.name, attributes, writer:)
            end
          end
        end

        def portable_reflection?(reflection)
          PortableClass.portable_classes.include?(reflection.klass) &&
            !reflection.polymorphic? &&
            !reflection.union_of?
        end
      end
    end
  end
end
