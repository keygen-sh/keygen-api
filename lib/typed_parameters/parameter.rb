# frozen_string_literal: true

require_relative 'path'

module TypedParameters
  class Parameter
    attr_accessor :key,
                  :value

    attr_reader :schema,
                :parent

    def initialize(key:, value:, schema:, parent: nil)
      @key       = key
      @value     = value
      @schema    = schema
      @parent    = parent
      @validated = false
    end

    def path = @path ||= Path.new(*parent&.path&.keys, *key)

    def key?(key) = keys.include?(key)
    alias :has_key? :key?

    def keys?(*keys) = keys.all? { key?(_1) }
    alias :has_keys? :keys?

    def keys
      return [] if
        schema.children.blank?

      case value
      when Array
        (0...value.size).to_a
      when Hash
        value.keys
      else
        []
      end
    end

    def validate!
      # TODO(ezekg) Add validations

      @validated = true
    end

    def validated?
      !!validated && ((schema.children.is_a?(Array) && value.all?(&:validated?)) ||
                      (schema.children.is_a?(Hash) && value.all? { |k, v| v.validated? }) ||
                       schema.children.nil?)
    end

    def permitted? = validated?

    def blank? = value.blank?

    def optional? = schema.optional?
    def required? = !optional?
    def parent?   = parent.present?

    def delete
      raise NotImplementedError, "cannot delete param: #{key.inspect}" unless
        parent?

      case parent.value
      when Array
        parent.value.delete(self)
      when Hash
        parent.value.delete(
          parent.value.key(self),
        )
      end
    end

    def [](key) = value[key]
    def []=(key, value)
      raise NotImplementedError, "cannot set key-value for non-hash: #{schema.type}" unless
        schema.hash?

      raise ArgumentError, 'value must be a parameter' unless
        value.nil? || value.is_a?(Parameter)

      self.value.merge!(key => value)
    end

    def <<(value)
      raise NotImplementedError, "cannot push to non-array: #{schema.type}" unless
        schema.array?

      raise ArgumentError, 'value must be a parameter' unless
        value.nil? || value.is_a?(Parameter)

      self.value.push(value)
    end

    def each(...) = value.each(...)

    def safe
      # TODO(ezekg) Raise if parameter is invalid

      case value
      when Array
        value.map { _1&.safe }
      when Hash
        value.transform_values { _1&.safe }
      else
        value
      end
    end

    def unsafe
      case value
      when Array
        value.map { _1&.unsafe }
      when Hash
        value.transform_values { _1&.unsafe }
      else
        value
      end
    end

    def deconstruct_keys(keys) = { key:, value: }
    def deconstruct            = value

    def inspect
      "#<TypedParameters::Parameter key=#{key.inspect} value=#{unsafe.inspect}>"
    end

    private

    attr_reader :validated
  end
end
