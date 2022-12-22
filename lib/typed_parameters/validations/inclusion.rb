# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Inclusion < Validation
      def call(value)
        case options
        in in: Range | Array => e
          e.include?(value)
        end
      end
    end
  end
end
