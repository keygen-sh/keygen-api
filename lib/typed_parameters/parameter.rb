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
      !!@validated && ((schema.children.is_a?(Array) && value.all?(&:validated?)) ||
                       (schema.children.is_a?(Hash) && value.all? { |k, v| v.validated? }) ||
                        schema.children.nil?)
    end

    def blank? = value.blank?

    def inspect = "#<Parameter:#{hash} @value=#{safe}>"

    def delete
      puts delete: value
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

    def safe
      # raise unless validated?

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
