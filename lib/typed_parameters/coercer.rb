# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Coercer < Mapper
    def call(params)
      depth_first_map(params) do |param|
        next unless
          param.schema.coerce?

        type = Types.for(param.value)

        raise InvalidParameterError.new("cannot coerce #{type} (#{param.schema.type} is not coerceable)", path: param.path) unless
          param.schema.type.coercable?

        param.value = param.schema.type.coerce(param.value)
      rescue FailedCoercionError
        raise InvalidParameterError.new("failed to coerce #{type} to #{param.schema.type}", path: param.path)
      end
    end
  end
end
