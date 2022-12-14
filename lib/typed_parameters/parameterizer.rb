# frozen_string_literal: true

module TypedParameters
  class Parameterizer
    def initialize(schema:, parent: nil)
      @schema = schema
      @parent = parent
    end

    def call(key: ROOT, value:)
      return value if
        value.is_a?(Parameter) ||
        value.nil?

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
      param = Parameter.new(key:, value: {}, schema:, parent:)

      raise UnpermittedParameterError.new('unpermitted parameter type (expected object)', path: param.path) unless
        value.is_a?(Hash)

      value.each do |k, v|
        if schema.children.any?
          child = schema.children.fetch(k) { nil }
          if child.nil?
            raise UnpermittedParameterError.new('unpermitted parameter', path: Path.new(*param.path.keys, k)) if
              schema.strict?

            next
          end

          param[k] = Parameterizer.new(schema: child, parent: param).call(key: k, value: v)
        else
          param[k] = Parameter.new(key: k, value: v, schema:, parent: param)
        end
      end

      param
    end

    def parameterize_array_schema(key:, value:)
      param = Parameter.new(key:, value: [], schema:, parent:)

      raise UnpermittedParameterError.new('unpermitted parameter type (expected array)', path: param.path) unless
        value.is_a?(Array)

      value.each_with_index do |v, i|
        if schema.children.any?
          child = schema.children.fetch(i) { schema.boundless? ? schema.children.first : nil }
          if child.nil?
            raise UnpermittedParameterError.new('unpermitted parameter', path: Path.new(*param.path.keys, i)) if
              schema.strict?

            next
          end

          param << Parameterizer.new(schema: child, parent: param).call(key: i, value: v)
        else
          param << Parameter.new(key: i, value: v, schema:, parent: param)
        end
      end

      param
    end

    def parameterize_value(key:, value:)
      Parameter.new(key:, value:, schema:, parent:)
    end
  end
end
