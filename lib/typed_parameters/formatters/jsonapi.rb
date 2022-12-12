# frozen_string_literal: true

require_relative 'formatter'

module TypedParameters
  module Formatters
    ##
    # The JSONAPI formatter transforms a JSONAPI document into Rails'
    # standard params format that can be passed to a model.
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
      def self.call(params)
        case params
        in data: Array => data
          format_array_data(data)
        in data: Hash => data
          format_hash_data(data)
        else
          params
        end
      end

      private

      def self.format_array_data(data)
        data.map { format_hash_data(_1) }
      end

      def self.format_hash_data(data)
        rels  = data[:relationships]
        attrs = data[:attributes]
        res   = data.slice(:id)

        # Move attributes over to top-level params
        attrs&.each do |key, attr|
          res[key] = attr
        end

        # Move relationships over. This will use x_id and x_ids when the
        # relationship data only contains :type and :id, otherwise it
        # will use the x_attributes key.
        rels&.each do |key, rel|
          case rel
          # FIXME(ezekg) We need https://bugs.ruby-lang.org/issues/18961 to
          #              clean this up (i.e. remove the if guard).
          in data: [{ type:, id:, **nil }, *] => linkage if linkage.all? { _1 in type:, id:, **nil }
            res[:"#{key.to_s.singularize}_ids"] = linkage.map { _1[:id] }
          in data: []
            res[:"#{key.to_s.singularize}_ids"] = []
          in data: { type:, id:, **nil } => linkage
            res[:"#{key}_id"] = linkage[:id]
          in data: nil
            res[:"#{key}_id"] = nil
          else
            res[:"#{key}_attributes"] = call(rel)
          end
        end

        res
      end
    end

    register(:jsonapi,
      transform: JSONAPI.method(:call),
    )
  end
end
