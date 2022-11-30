# frozen_string_literal: true

module TypedParameters
  class Parameterizer
    def initialize(schema:, parent: nil)
      @schema = schema
      @parent = parent
    end

    def call(key: nil, value:)
      return value if value.is_a?(Parameter)
      return if
        value.nil? && !schema.allow_nil?

      case schema.children
      when Hash
        parameterize_hash_schema(key:, value:)
      when Array
        parameterize_array_schema(key:, value:)
      else
        parameterize_value(key:, value:)
      end
    end

    private

    attr_reader :schema,
                :parent

    def parameterize_hash_schema(key:, value:)
      param = Parameter.new(key:, value: {}.with_indifferent_access, schema:, parent:)

      value.each do |k, v|
        if schema.children.any?
          child = schema.children.fetch(k) { nil }
          if child.nil?
            raise InvalidParameterError, "invalid parameter key: #{k.inspect}" if
              schema.strict?

            next
          end

          param.append(
            k => Parameterizer.new(schema: child, parent: param).call(key: k, value: v),
          )
        else
          param.append(
            k => Parameter.new(key: k, value: v, schema:, parent: param),
          )
        end
      end

      param
    end

    def parameterize_array_schema(key:, value:)
      param = Parameter.new(key:, value: [], schema:, parent:)

      value.each_with_index do |v, i|
        if schema.children.any?
          # FIXME(ezekg) This should probably raise for bounded arrays instead of
          #              defaulting to the first child.
          child = schema.children.fetch(i) { schema.children.first }
          if child.nil?
            raise InvalidParameterError, "invalid parameter index: #{i.inspect}" if
              schema.strict?

            next
          end

          param.append(
            Parameterizer.new(schema: child, parent: param).call(key: i, value: v),
          )
        else
          param.append(
            Parameter.new(key: i, value: v, schema:, parent: param),
          )
        end
      end

      param
    end

    def parameterize_value(key:, value:)
      Parameter.new(key:, value:, schema:, parent:)
    end
  end
end
