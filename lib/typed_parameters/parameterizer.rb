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
        value = Types.coerce(value, to: :hash) unless
          Types.hash?(value)

        convert_hash(key:, value:)
      when Array
        value = Types.coerce(value, to: :array) unless
          Types.array?(value)

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
        if schema.children.any?
          child = schema.children.fetch(k) { nil }
          if child.nil?
            raise InvalidParameterError, "invalid parameter key #{k}" if
              schema.strict?

            next
          end

          param.append(
            k => Parameterizer.new(schema: child, parent: param).call(key: k, value: v),
          )
        else
          raise InvalidParameterError, 'unpermitted type (expected object of scalar types)' unless
            Types.scalar?(v)

          param.append(
            k => Parameter.new(key: k, value: v, schema:, parent: param),
          )
        end
      end

      param
    end

    def convert_array(key:, value:)
      param = Parameter.new(key:, value: [], schema:, parent:)

      value.each_with_index do |v, i|
        if schema.children.any?
          child = schema.children.fetch(i) { schema.children.first }
          if child.nil?
            raise InvalidParameterError, "invalid parameter index #{i}" if
              schema.strict?

            next
          end

          param.append(
            Parameterizer.new(schema: child, parent: param).call(key: i, value: v),
          )
        else
          raise InvalidParameterError, 'unpermitted type (expected array of scalar types)' unless
            Types.scalar?(v)

          param.append(
            Parameter.new(key: i, value: v, schema:, parent: param),
          )
        end
      end

      param
    end

    def convert_scalar(key:, value:)
      Parameter.new(key:, value:, schema:, parent:)
    end
  end
end
