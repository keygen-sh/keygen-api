# frozen_string_literal: true

require_relative 'rule'

module TypedParameters
  class Coercer < Rule
    def call(params)
      depth_first_map(params) do |param|
        next unless
          param.schema.coerce?

        type = Types.for(param.value)

        raise InvalidParameterError, "cannot coerce to #{param.schema.type} (#{type} is not coerceable)" unless
          param.schema.type.coercable?

        param.value = param.schema.type.coerce(param.value)
      rescue FailedCoercionError
        raise InvalidParameterError, "failed to coerce #{type} to #{param.schema.type}"
      end
    end
  end
end
