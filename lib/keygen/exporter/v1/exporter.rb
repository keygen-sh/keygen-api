# frozen_string_literal: true

require_relative 'serializer'
require_relative 'writer'

module Keygen
  module Exporter
    module V1
      class Exporter
        BATCH_SIZE = 1_000

        def initialize(account, secret_key: nil)
          @account    = account
          @serializer = Serializer.new(secret_key:)
        end

        def export(to: StringIO.new)
          writer = Writer.new(to)
          writer.write_version

          export_record(account.class.name, account.attributes_for_export, writer:)
          export_associations(account, writer:)

          writer.to_reader
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
            next unless exportable_reflection?(reflection)

            association = owner.association(reflection.name)
            scope       = association.scope

            scope.in_batches(of: BATCH_SIZE) do |records|
              attributes = records.map(&:attributes_for_export)

              export_records(reflection.klass.name, attributes, writer:)
            end
          end
        end

        def exportable_reflection?(reflection)
          Exportable.classes.include?(reflection.klass) &&
            !reflection.polymorphic? &&
            !reflection.union_of?
        end
      end
    end
  end
end
