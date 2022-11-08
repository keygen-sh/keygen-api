# frozen_string_literal: true

module TypedParameters
  class Parameterizer
    def initialize(schema:, parent: nil)
      @schema = schema
      @parent = parent
    end

    def convert(data)
      return if
        data.nil?

      case schema.children
      when Hash
        convert_hash(data)
      when Array
        convert_array(data)
      else
        convert_scalar(data)
      end
    end

    private

    attr_reader :schema,
                :parent

    def convert_hash(data)
      param = Parameter.new(value: {}, schema:, parent:)

      schema.children.each do |key, child|
        value = data.fetch(key) { nil }
        next if
          value.nil?

        param.append(
          key => Parameterizer.new(schema: child, parent: param).convert(value),
        )
      end

      param
    end

    def convert_array(data)
      param = Parameter.new(value: [], schema:, parent:)

      data.each_with_index do |value, i|
        child = schema.children.fetch(i) { schema.children.first }
        next if
          child.nil?

        param.append(
          Parameterizer.new(schema: child, parent: param).convert(value),
        )
      end

      param
    end

    def convert_scalar(value)
      Parameter.new(value:, schema:, parent:)
    end
  end
end
