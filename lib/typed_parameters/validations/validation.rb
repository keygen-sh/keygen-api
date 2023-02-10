# frozen_string_literal: true

module TypedParameters
  module Validations
    class Validation
      def initialize(options) = @options = options
      def call(value)         = raise NotImplementedError

      def self.wrap(fn)
        -> v { raise ValidationError, 'is invalid' unless fn.call(v) }
      end

      private

      attr_reader :options
    end
  end
end
