# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Transformer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema

        schema.transforms.map do |transform|
          param.key, param.value = transform.call(param.key, param.value)

          param.delete if param.key.nil? && param.value.nil?
        end
      end
    end
  end
end
