# frozen_string_literal: true

module TypedParameters
  class Parameterizer
    def initialize(schema:, parent: nil)
      @schema = schema
      @parent = parent
    end

    def call(key: nil, value:)
      return if
        value.nil?

      case schema.children
      when Hash
        convert_hash(key:, value:)
      when Array
        convert_array(key:, value:)
      else
        convert_scalar(key:, value:)
      end
    end

    private

    attr_reader :schema,
                :parent

    def convert_hash(key:, value:)
      param = Parameter.new(key:, value: {}, schema:, parent:)

      value.each do |k, v|
        child = schema.children.fetch(k) { nil }
        if child.nil?
          raise InvalidParameterError, "invalid parameter key #{k}" if
            schema.strict?

          next
        end

        param.append(
          k => Parameterizer.new(schema: child, parent: param).call(key: k, value: v),
        )
      end

      param
    end

    def convert_array(key:, value:)
      param = Parameter.new(key:, value: [], schema:, parent:)

      value.each_with_index do |v, i|
        child = schema.children.fetch(i) { schema.children.first }
        if child.nil?
          raise InvalidParameterError, "invalid parameter index #{i}" if
            schema.strict?

          next
        end

        param.append(
          Parameterizer.new(schema: child, parent: param).call(key: i, value: v),
        )
      end

      param
    end

    def convert_scalar(key:, value:)
      Parameter.new(key:, value:, schema:, parent:)
    end
  end
end
