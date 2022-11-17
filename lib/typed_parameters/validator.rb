# frozen_string_literal: true

require_relative 'rule'

module TypedParameters
  class Validator < Rule
    def call(params)
      depth_first_map(params) do |param|
        type = Types.for(param.value)

        raise InvalidParameterError.new(path: param.path), "type mismatch (received unknown expected #{params.schema.type.name})" if
          type.nil?

        raise InvalidParameterError.new(path: param.path), "type mismatch (received #{type.name} expected #{params.schema.type.name})" if
          # !(param.coerce? && param.schema.type.coercable?) &&
          param.schema.type != type
      end
    end
  end
end
