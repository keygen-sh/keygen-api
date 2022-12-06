# frozen_string_literal: true

require_relative 'format'

module TypedParameters
  module Formats
    module JSONAPI
      IGNORED_KEYS = %i[type meta links].freeze

      def self.call(params)
        schema = params.schema

        case params.value
        in data: Parameter(value: Array) => data
          params.value = format_array_data(data)
        in data: Parameter(value: Hash) => data
          params.value = format_hash_data(data)
        else
        end

        params
      end

      private

      def self.format_array_data(data)
        data.value.each { format_hash_data(_1) }
      end

      def self.format_hash_data(data)
        attributes    = data[:attributes]&.delete
        relationships = data[:relationships]&.delete

        IGNORED_KEYS.each { data[_1]&.delete }
        attributes&.each  { data[_1] = _2 }

        # TODO(ezekg) Should this use x_id/x_ids when only IDs are provided?
        relationships&.each { data["#{_1}_attributes"] = call(_2) }

        data.value
      end
    end

    register(:jsonapi,
      handler: -> params { JSONAPI.call(params) },
      # decorator: -> controller {
      #   controller.define_method(:typed_meta) { ... }
      # },
    )
  end
end
