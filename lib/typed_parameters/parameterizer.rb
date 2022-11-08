# frozen_string_literal: true

module TypedParameters
  class Parameterizer
    def initialize(schema:, parent: nil)
      @schema = schema
      @parent = parent
    end

    def wrap(data)
      return if
        data.nil?

      case schema.children
      when Hash
        wrap_hash(data)
      when Array
        wrap_array(data)
      else
        wrap_scalar(data)
      end
    end

    private

    attr_reader :schema,
                :parent

    def wrap_hash(data)
      param = Parameter.new(value: {}, schema:, parent:)

      schema.children.each do |key, child|
        value = data.fetch(key) { nil }
        next if
          value.nil?

        param.merge!(
          key => Parameterizer.new(schema: child, parent: param).wrap(value),
        )
      end

      param
    end

    def wrap_array(data)
      param = Parameter.new(value: [], schema:, parent:)

      data.each_with_index do |value, i|
        child = schema.children.fetch(i) { schema.children.first }
        next if
          child.nil?

        param.push(
          Parameterizer.new(schema: child, parent: param).wrap(value),
        )
      end

      param
    end

    def wrap_scalar(value)
      Parameter.new(value:, schema:, parent:)
    end
  end
end
