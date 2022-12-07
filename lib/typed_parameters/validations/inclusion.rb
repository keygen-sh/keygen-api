# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Inclusion < Validation
      def call(value)
        case options
        in in: Array => a
          a.include?(value)
        end
      end
    end
  end
end
