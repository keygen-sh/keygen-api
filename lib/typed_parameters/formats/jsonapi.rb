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

        # Remove ignored keys
        IGNORED_KEYS.each { data[_1]&.delete }

        # Move attributes over to top-level params
        attributes&.each do |key, value|
          data[key] = value
        end

        # Move relationships over. This will use x_id and x_ids when the
        # relationship data only contains :type and :id, otherwise it
        # will use the x_attributes key.
        relationships&.each do |key, value|
          case value
          # FIXME(ezekg) We need https://bugs.ruby-lang.org/issues/18961 to
          #              clean this up (i.e. remove the if guard).
          in Parameter(value: { data: Parameter(value: [Parameter(value: { type:, id:, **nil }), *]) => linkage }) if linkage.value.all? { _1 in Parameter(value: { type:, id:, **nil }) }
            linkage.value = linkage.value.map { _1[:id] }

            data["#{key.singularize}_ids"] = linkage
          in Parameter(value: { data: Parameter(value: { type:, id:, **nil }) => linkage })
            data["#{key}_id"] = linkage[:id]
          else
            data["#{key}_attributes"] = call(value)
          end
        end

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
