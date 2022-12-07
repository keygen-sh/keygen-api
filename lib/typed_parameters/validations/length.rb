# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Length < Validation
      def call(value)
        case options
        in minimum: Numeric => n
          value.length >= n
        in maximum: Numeric => n
          value.length <= n
        in within: Range => r
          r.include?(value.length)
        in in: Range => r
          r.include?(value.length)
        in is: Numeric => n
          value.length == n
        end
      end
    end
  end
end
