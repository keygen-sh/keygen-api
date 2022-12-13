# frozen_string_literal: true

module TypedParameters
  module Formatters
    class Formatter
      extend Forwardable

      attr_reader :format

      def initialize(format, transform:)
        @format    = format
        @transform = transform
      end

      def call(...) = @transform.call(...)

      delegate arity: :@transform
    end
  end
end
