# frozen_string_literal: true

require_relative 'rule'

module TypedParameters
  class Validator < Rule
    def call(params)
      depth_first_map(params) do |param|
        type = Types.for(param.value)

        raise InvalidParameterError.new(path: param.path), "type mismatch (received unknown expected #{param.schema.type.name})" if
          type.nil?

        raise InvalidParameterError.new(path: param.path), "type mismatch (received #{type.name} expected #{param.schema.type.name})" if
          param.schema.type != type
      end
    end
  end
end
