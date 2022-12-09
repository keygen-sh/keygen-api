# frozen_string_literal: true

require_relative 'mapper'

module TypedParameters
  class Validator < Mapper
    def call(params)
      raise InvalidParameterError.new('is missing', path: schema.path) if
        params.nil? && schema.required? && !schema.allow_nil?

      depth_first_map(params) do |param|
        type   = Types.for(param.value)
        schema = param.schema

        raise InvalidParameterError.new("type mismatch (received unknown expected #{schema.type.name})", path: param.path) if
          type.nil?

        # Handle nils early on
        if Types.nil?(type)
          raise InvalidParameterError.new('cannot be nil', path: param.path) unless
            schema.required? && schema.allow_nil?

          next
        end

        # Assert type
        raise InvalidParameterError.new("type mismatch (received #{type.name} expected #{schema.type.name})", path: param.path) if
          schema.type != type

        # Assert scalar values for params without children
        if schema.children.nil?
          case
          when Types.hash?(schema.type)
            param.value.each do |key, value|
              next if
                Types.scalar?(value)

              path = Path.new(*param.path.keys, key)

              raise InvalidParameterError.new('unpermitted type (expected object of scalar types)', path:) unless
                schema.allow_non_scalars?
            end
          when Types.array?(schema.type)
            param.value.each_with_index do |value, index|
              next if
                Types.scalar?(value)

              path = Path.new(*param.path.keys, index)

              raise InvalidParameterError.new('unpermitted type (expected array of scalar types)', path:) unless
                schema.allow_non_scalars?
            end
          end
        end

        # Handle blanks
        if param.value.blank?
          raise InvalidParameterError.new('cannot be blank', path: param.path) if
            !schema.allow_blank?

          next
        end

        # Assert validations
        raise InvalidParameterError.new('is invalid', path: param.path) unless
          schema.validations.all? { _1.call(param.value) }
      end
    end
  end
end
