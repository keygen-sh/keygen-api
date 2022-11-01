# frozen_string_literal: true

module TypedParameters
  module Types
    class Type
      attr_reader :type,
                  :name

      def initialize(type:, name:, match:, coerce:, scalar:, accepts_block:)
        @type   = type
        @name   = name
        @match  = match
        @coerce = coerce
        @scalar = scalar
        @block  = accepts_block
      end

      def accepts_block? = !!@block
      def coercable?     = @coerce.present?
      def scalar?        = !!@scalar

      def match?(v)    = v == self || !!@match.call(v)
      def mismatch?(v) = !match?(v)

      def to_sym = type.to_sym
      def to_s   = type.to_s

      def coerce!(...)
        raise NotImplementedError, 'type is not coercable' unless coercable?

        @coerce.call(...)
      rescue
        raise CoerceFailedError, 'failed to coerce'
      end

      def call(...) = @block.call(...)
    end
  end
end
