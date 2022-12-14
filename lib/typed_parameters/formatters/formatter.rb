# frozen_string_literal: true

module TypedParameters
  module Formatters
    class Formatter
      extend Forwardable

      attr_reader :decorator,
                  :format

      def initialize(format, transform:, decorate:)
        @format    = format
        @transform = transform
        @decorator = decorate
      end

      def call(...)  = @transform.call(...)
      def decorator? = @decorator.present?

      delegate arity: :@transform
    end
  end
end
