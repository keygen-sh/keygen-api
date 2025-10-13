# frozen_string_literal: true

require_relative 'deserializer'
require_relative 'reader'

module Keygen
  module Importer
    module V1
      class Importer
        def initialize(account_id:, secret_key: nil)
          @account_id   = account_id
          @deserializer = Deserializer.new(secret_key:)
        end

        def import(from:)
          reader = Reader.new(from)

          while chunk = reader.read_chunk
            process_chunk(chunk)
          end
        end

        private

        attr_reader :account_id,
                    :deserializer

        def process_chunk(chunk)
          class_name, attributes = deserializer.deserialize(chunk)

          import_records!(class_name, attributes)
        end

        def import_records!(class_name, attributes)
          klass = class_name.constantize

          klass.transaction do
            raise UnsupportedRecordError unless importable_class?(klass)

            records = klass.import_all!(attributes)

            validate_records!(records)
          rescue ActiveRecord::RecordNotUnique
            raise DuplicateRecordError
          end
        end

        def validate_records!(records)
          case records
          in [Account => account]
            # assert account is expected account
            raise InvalidAccountError unless account.id == account_id
          else
            # assert records are for account
            raise InvalidRecordError unless records.all? { it.account_id == account_id }
          end
        end

        def importable_class?(klass)
          PortableClass.portable_classes.include?(klass)
        end
      end
    end
  end
end
