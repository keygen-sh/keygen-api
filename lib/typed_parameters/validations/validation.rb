# frozen_string_literal: true

module TypedParameters
  module Validations
    class Validation
      def initialize(options) = @options = options
      def call(value)         = raise NotImplementedError

      # FIXME(ezekg) Is there a cleaner way of delegating arity?
      def arity = method(:call).arity

      private

      attr_reader :options
    end
  end
end
