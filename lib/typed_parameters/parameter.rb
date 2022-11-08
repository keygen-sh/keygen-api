# frozen_string_literal: true

module TypedParameters
  class Parameter
    attr_reader :value,
                :schema,
                :parent,
                :validated

    def initialize(value:, schema:, parent: nil)
      @value     = value
      @schema    = schema
      @parent    = parent
      @validated = false
    end

    def permitted? = validated

    def validated! = @validated = true
    def validated?
      !!@validated #&& ((schema.children.is_a?(Array) && value.all?(&:validated?)) ||
                   #    (schema.children.is_a?(Hash) && value.all? { |k, v| v.validated? }) ||
                   #     schema.children.nil?)
    end

    def [](key) = value[key]

    def merge!(...) = value.merge!(...)
    def push(...) = value.push(...)
    def any? = yield value

    def safe
      raise unless validated?

      case value
      when Array
        value.map(&:safe)
      when Hash
        value.transform_values(&:safe)
      else
        value
      end
    end
  end
end
