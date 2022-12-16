# frozen_string_literal: true

module TypedParameters
  module Formatters
    class Formatter
      attr_reader :decorator,
                  :format

      def initialize(format, transform:, decorate:)
        @format    = format
        @transform = transform
        @decorator = decorate
      end

      def decorator? = decorator.present?

      delegate :arity, :call, to: :@transform
    end
  end
end
