# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Transformer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema
        parent = param.parent

        schema.transforms.map do |transform|
          key, value = transform.call(param.key, param.value)
          if key.nil? && value.nil?
            param.delete

            break
          end

          # If param's key has changed, we want to rename the key
          # for its parent too.
          if param.parent.present? && param.key != key
            parent[param.key].delete
            parent[key] = param
          end

          param.key, param.value = key, value
        end
      end
    end
  end
end
