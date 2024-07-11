# frozen_string_literal: true

require_relative 'deserializer'
require_relative 'reader'

module Keygen
  module Importer
    module V1
      class Importer
        def initialize(secret_key: nil)
          @deserializer = Deserializer.new(secret_key:)
        end

        def import(from:)
          reader = Reader.new(from)

          while chunk = reader.read_chunk
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

          klass.insert_all(klass.attributes_for_import(attributes))
        end
      end
    end
  end
end
