# frozen_string_literal: true

require_relative 'formatter'

module TypedParameters
  module Formatters
    module Rails
      def self.call(key, value, controller:)
        key = controller.controller_name.singularize.to_sym

        [
          key,
          {
            key => Parameter.new(key:, value:, schema: nil),
          },
        ]
      end
    end

    register(:rails,
      transform: -> k, v, c { Rails.call(k, v, controller: c) },
    )
  end
end
