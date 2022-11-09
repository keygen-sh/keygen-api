# frozen_string_literal: true

module TypedParameters
  class Parameter
    attr_reader :value,
                :schema,
                :parent

    def initialize(value:, schema:, parent: nil)
      @value     = value
      @schema    = schema
      @parent    = parent
      @validated = false
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

    def inspect = "#<Parameter:#{hash} @value=#{to_unsafe_h} @validated=#{validated}>"

    def delete
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

    def append(*args, **kwargs) = kwargs.present? ? value.merge!(**kwargs) : value.push(*args)

    def to_safe_h
      Validator.validate!(self)

      case value
      when Array
        value.map(&:to_safe_h)
      when Hash
        value.transform_values(&:to_safe_h)
      else
        value
      end
    end

    def to_unsafe_h
      case value
      when Array
        value.map(&:to_unsafe_h)
      when Hash
        value.transform_values(&:to_unsafe_h)
      else
        value
      end
    end

    private

    attr_reader :validated
  end
end
