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
            records = klass.import_all!(attributes)

            validate_records!(records)
          rescue ActiveRecord::RecordNotUnique
            raise DuplicateRecordError
          end
        end

        def validate_records!(records)
          case records
          in [Account => account] if account.id == account_id
            # ok -- account is expected account
          in [*] if records.all? { !_1.respond_to?(:account_id) || _1.account_id == account_id }
            # ok -- records are for account
          else
            raise InvalidRecordError
          end
        end
      end
    end
  end
end
