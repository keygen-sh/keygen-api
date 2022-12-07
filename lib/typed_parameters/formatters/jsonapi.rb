# frozen_string_literal: true

require_relative 'formatter'

module TypedParameters
  module Formatters
    ##
    # The JSONAPI formatter transforms a JSONAPI document into Rails'
    # standard params format.
    #
    # For example, given the following params:
    #
    #   {
    #     data: {
    #       type: 'users',
    #       id: '1',
    #       attributes: { email: 'foo@bar.example' },
    #       relationships: {
    #         friends: {
    #           data: [{ type: 'users', id: '2' }]
    #         }
    #       }
    #     }
    #   }
    #
    # The final params would become:
    #
    #   {
    #     id: '1',
    #     email: 'foo@bar.example',
    #     friend_ids: ['2']
    #   }
    #
    module JSONAPI
      IGNORED_KEYS = %i[type meta links].freeze

      def self.call(key, value)
        case value
        in data: Parameter(value: Array) => data
          value = format_array_data(data)
        in data: Parameter(value: Hash) => data
          value = format_hash_data(data)
        else
          puts(:other, value:)
        end

        [key, value]
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

            data[:"#{key.to_s.singularize}_ids"] = linkage
          in Parameter(value: { data: Parameter(value: { type:, id:, **nil }) => linkage })
            data[:"#{key}_id"] = linkage[:id]
          else
            value.key, value.value = call(value.key, value.value)

            data[:"#{key}_attributes"] = value
          end
        end

        data.value
      end
    end

    register(:jsonapi,
      transform: -> k, v { JSONAPI.call(k, v) },
      # decorator: -> controller {
      #   controller.define_method(:typed_meta) { ... }
      # },
    )
  end
end
