# frozen_string_literal: true

module TypedParameters
  module Validations
    class Validation
      def initialize(options) = @options = options
      def call(value)         = raise NotImplementedError

      private

      attr_reader :options
    end
  end
end
