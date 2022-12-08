# frozen_string_literal: true

module TypedParameters
  module Formatters
    class Formatter
      attr_reader :format

      def initialize(format, transform:)
        @format    = format
        @transform = transform
      end

      def call(...) = @transform.call(...)

      # FIXME(ezekg) Is there a cleaner way of delegating arity?
      def arity = @transform.arity
    end
  end
end
