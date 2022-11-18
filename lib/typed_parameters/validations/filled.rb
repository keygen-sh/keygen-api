# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Filled < Validation
      def call(param)
        raise InvalidParameterError.new, 'cannot be blank' if
          !schema.allow_blank? && param.value.blank? && param.value != false
      end
    end
  end
end
