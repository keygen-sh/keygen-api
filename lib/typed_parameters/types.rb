# frozen_string_literal: true

require_relative './types/type'

module TypedParameters
  module Types
    cattr_reader :types, default: {}

    def self.register(type:, name: type, match:, coerce: nil, scalar: true, accepts_block: false)
      raise ArgumentError, 'type is already registered' if
        types.key?(type)

      types[type] = Type.new(type:, name:, match:, coerce:, scalar:, accepts_block:)

      define_singleton_method(:"#{type}?") { types[type].match?(_1) }
    end

    def self.coerce(value, to:) = types[to].coerce(value)

    def self.scalar?(value) = self.for(value).scalar?

    def self.for(value) = types.values.find { _1.match?(value) }
    def self.[](type)   = types[type] || raise(ArgumentError, %(invalid type "#{type}"))
  end
end
