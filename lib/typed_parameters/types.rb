# frozen_string_literal: true

require_relative './types/type'

module TypedParameters
  module Types
    cattr_reader :types, default: {}

    def self.register(type:, name: type, match:, coerce: nil, scalar: true, accepts_block: false)
      types[type] = Type.new(type:, name:, match:, coerce:, scalar:, accepts_block:)
    end

    def self.for(value) = types.values.find { _1.match?(value) }
    def self.[](type)   = types[type]
  end
end
