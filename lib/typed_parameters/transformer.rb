# frozen_string_literal: true

require_relative 'rule'

module TypedParameters
  class Transformer < Rule
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema

        schema.transforms.map do |transform|
          case transform.arity
          when 3
            param.key, param.value = transform.call(param.key, param.value, controller)
          when 2
            param.key, param.value = transform.call(param.key, param.value)
          end

          param.delete if param.key.nil? && param.value.nil?
        end
      end
    end
  end
end
