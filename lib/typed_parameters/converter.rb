# frozen_string_literal: true

module TypedParameters
  class Converter
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

      data.each do |key, value|
        child = schema.children.fetch(key) { nil }
        if child.nil?
          raise InvalidParameterError, "invalid parameter key #{key}" if
            schema.strict?

          next
        end

        param.append(
          key => Converter.new(schema: child, parent: param).convert(value),
        )
      end

      param
    end

    def convert_array(data)
      param = Parameter.new(value: [], schema:, parent:)

      data.each_with_index do |value, i|
        child = schema.children.fetch(i) { schema.children.first }
        if child.nil?
          raise InvalidParameterError, "invalid parameter index #{i}" if
            schema.strict?

          next
        end

        param.append(
          Converter.new(schema: child, parent: param).convert(value),
        )
      end

      param
    end

    def convert_scalar(value)
      Parameter.new(value:, schema:, parent:)
    end
  end
end
