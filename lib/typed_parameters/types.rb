# frozen_string_literal: true

require_relative 'types/type'

module TypedParameters
  module Types
    cattr_reader :registry,  default: []
    cattr_reader :abstracts, default: {}
    cattr_reader :subtypes,  default: {}
    cattr_reader :types,     default: {}

    def self.register(type, match:, name: nil, coerce: nil, archetype: nil, abstract: false, scalar: true, accepts_block: false)
      raise ArgumentError, "type is already registered: #{type.inspect}" if
        registry.include?(type)

      registry << type

      t = Type.new(type:, name:, match:, coerce:, archetype:, abstract:, scalar:, accepts_block:)
      case
      when abstract
        abstracts[type] = t
      when archetype
        subtypes[type] = t
      else
        types[type] = t
      end
    end

    def self.unregister(type)
      return unless
        registry.include?(type)

      t = abstracts.delete(type) || subtypes.delete(type) || types.delete(type)

      registry.delete(type) if
        t.present?

      t
    end

    def self.coerce(value, to:) = (subtypes[to] || types[to]).coerce(value)

    def self.array?(value)  = types[:array].match?(value)
    def self.hash?(value)   = types[:hash].match?(value)
    def self.nil?(value)    = types[:nil].match?(value)
    def self.scalar?(value) = self.for(value).scalar?

    def self.[](key)
      type = abstracts[key] ||
             subtypes[key] ||
             types[key]

      raise ArgumentError, "invalid type: #{key.inspect}" if
        type.nil?

      type
    end

    def self.for(value)
      _, type = subtypes.find { |_, t| t.match?(value) } ||
                types.find { |_, t| t.match?(value) }

      raise ArgumentError, "cannot find type for value: #{value.inspect}" if
        type.nil?

      type
    end
  end
end
