# frozen_string_literal: true

module TypedParameters
  module Types
    class Type
      attr_reader :type,
                  :name

      def initialize(type:, name:, match:, coerce:, scalar:, abstract:, archetype:, accepts_block:)
        raise ArgumentError, ':abstract not allowed with :archetype' if
          abstract && archetype.present?

        raise ArgumentError, ':abstract not allowed with :coerce' if
          abstract && coerce.present?

        raise ArgumentError, ':coerce must be callable' unless
          coerce.nil? || coerce.respond_to?(:call)

        raise ArgumentError, ':match must be callable' unless
          match.respond_to?(:call)

        @name          = name || type
        @type          = type
        @match         = match
        @coerce        = coerce
        @abstract      = abstract
        @archetype     = archetype
        @scalar        = scalar
        @accepts_block = accepts_block
      end

      def archetype
        return unless @archetype.present?

        return @archetype if
          @archetype.is_a?(Type)

        Types[@archetype]
      end

      def accepts_block? = !!@accepts_block
      def coercable?     = !!@coerce
      def scalar?        = !!@scalar
      def abstract?      = !!@abstract
      def subtype?       = !!@archetype

      # NOTE(ezekg) Using yoda-style self#== because value may be a Type, and
      #             we're overriding Type#coerce, which is a Ruby core method
      #             expected to return an [x, y] tuple, so v == self breaks.
      def match?(v)    = self == v || !!@match.call(v)
      def mismatch?(v) = !match?(v)

      def humanize
        if subtype?
          "#{@name} #{archetype.humanize}"
        else
          @name.to_s
        end
      end

      def to_sym = type.to_sym
      def to_s   = type.to_s

      def inspect
        "#<#{self.class.name} type=#{@type.inspect} name=#{@name.inspect} abstract=#{@abstract.inspect} archetype=#{@archetype.inspect}>"
      end

      def coerce(value)
        raise CoercionError, 'type is not coercable' unless
          coercable?

        @coerce.call(value)
      rescue
        raise CoercionError, "failed to coerce #{Types.for(value).name} to #{@name}"
      end
    end
  end
end
