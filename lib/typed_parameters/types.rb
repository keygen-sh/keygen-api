# frozen_string_literal: true

require_relative 'types/type'

module TypedParameters
  module Types
    cattr_reader :types, default: {}

    def self.register(type, name: type, match:, coerce: nil, scalar: true, accepts_block: false)
      raise DuplicateTypeError, "type is already registered: #{type.inspect}" if
        types.key?(type)

      types[type] = Type.new(type:, name:, match:, coerce:, scalar:, accepts_block:)
    end

    def self.unregister(type) = types.delete(type)

    def self.coerce(value, to:) = types[to].coerce(value)

    def self.array?(value)  = types[:array].match?(value)
    def self.hash?(value)   = types[:hash].match?(value)
    def self.nil?(value)    = types[:nil].match?(value)
    def self.scalar?(value) = self.for(value).scalar?

    # NOTE(ezekg) Reversing so that we access newer types first, to allow for
    #             more fine-grained custom types.
    def self.for(value) = types.values.reverse.find { _1.match?(value) }
    def self.[](type)   = types[type] || raise(ArgumentError, "invalid type: #{type.inspect}")
  end
end
