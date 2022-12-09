# frozen_string_literal: true

require_relative 'path'

module TypedParameters
  class Parameter
    attr_accessor :key,
                  :value

    attr_reader :schema,
                :parent

    def initialize(key:, value:, schema:, parent: nil)
      @key    = key
      @value  = value
      @schema = schema
      @parent = parent
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

    def each(...) = value.each(...)
    def <<(value)
      raise NotImplementedError, "cannot push to non-array: #{schema.type}" unless
        schema.array?

      raise ArgumentError, 'value must be a parameter' unless
        value.nil? || value.is_a?(Parameter)

      self.value.push(value)
    end

    def unwrap(formatter: schema.formatter, controller: nil)
      v = case value
          when Hash
            value.transform_values { _1.respond_to?(:unwrap) ? _1.unwrap : _1 }
          when Array
            value.map { _1.respond_to?(:unwrap) ? _1.unwrap : _1 }
          else
            value.respond_to?(:unwrap) ? value.unwrap : value
          end

      if formatter.present?
        v = case formatter.arity
            when 2
              formatter.call(v, controller:)
            when 1
              formatter.call(v)
            end
      end

      v
    end

    def deconstruct_keys(keys) = { key:, value: }
    def deconstruct            = value

    def inspect
      value = unwrap(formatter: nil)

      "#<#{self.class.name} key=#{key.inspect} value=#{value.inspect}>"
    end

    private

    def parent? = parent.present?
  end
end
