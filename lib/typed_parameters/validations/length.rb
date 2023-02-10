# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Length < Validation
      def call(value)
        case options
        in minimum: Numeric => n
          raise ValidationError, "length must be greater than or equal to #{n}" unless
            value.length >= n
        in maximum: Numeric => n
          raise ValidationError, "length must be less than or equal to #{n}" unless
            value.length <= n
        in within: Range | Array => e
          raise ValidationError, "length must be between #{e.first} and #{e.last}" unless
            e.include?(value.length)
        in in: Range | Array => e
          raise ValidationError, "length must be between #{e.first} and #{e.last}" unless
            e.include?(value.length)
        in is: Numeric => n
          raise ValidationError, "length must be equal to #{n}" unless
            value.length == n
        end
      end
    end
  end
end
