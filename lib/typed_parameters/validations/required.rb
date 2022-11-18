# frozen_string_literal: true

require_relative 'validation'

module TypedParameters
  module Validations
    class Required < Validation
      def call(param)
        param.parent.children&.each do |child|
          next unless
            child.key == param.key

          # raise InvalidParameterError, 'is required' if
          #   param.value
        end
      end
    end
  end
end
