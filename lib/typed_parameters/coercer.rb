# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Coercer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        schema = param.schema
        next unless
          schema.coerce?

        param.value = schema.type.coerce(param.value)
      rescue FailedCoercionError
        type = Types.for(param.value)

        raise InvalidParameterError.new("failed to coerce #{type} to #{schema.type}", path: param.path)
      end
    end
  end
end
