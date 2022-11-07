# frozen_string_literal: true

module TypedParameters
  class Validator
    def initialize(schema:)
      @schema = schema
    end

    def validate(data)
      return if
        data.nil?

      case schema.children
      when Hash
        validate_hash(data)
      when Array
        validate_array(data)
      else
        validate_scalar(data)
      end
    end

    private

    attr_reader :schema

    def validate_hash(data)
      res = {}

      schema.children.each do |key, child|
        value = data.fetch(key) { nil }

        next if
          value.nil?

        res.merge!(
          key => Validator.new(schema: child).validate(value),
        )
      end

      res
    end

    def validate_array(data)
      res = []

      data.each_with_index do |value, i|
        child = schema.children.fetch(i) { schema.children.first }

        next if
          child.nil?

        res.push(
          Validator.new(schema: child).validate(value),
        )
      end

      res
    end

    def validate_scalar(data)
      data
    end
  end
end
