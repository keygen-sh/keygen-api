# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Filled < Validation
      def validate
        raise InvalidParameterError.new, 'cannot be blank' if
          !params.allow_blank? && value.blank? && value != false
      end
    end
  end
end
