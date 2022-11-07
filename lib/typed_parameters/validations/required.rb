# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Required < Validation
      def validate
        raise InvalidParameterError, 'is required' if
          !params.allow_blank? && !params.optional? &&
          value.blank? && value != false
      end
    end
  end
end
