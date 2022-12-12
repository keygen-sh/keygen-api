# frozen_string_literal: true

require_relative 'transform'

module TypedParameters
  module Transforms
    class KeyCasing < Transform
      def initialize(casing = nil) = @casing = casing || TypedParameters.config.key_transform

      def call(key, value)
        transformed_key   = transform_key(key)
        transformed_value = case value
                            when Hash
                              value.deep_transform_keys { transform_key(_1) }
                            when Array
                              value.map { transform_value(_1) }
                            else
                              value
                            end

        [transformed_key, transformed_value]
      end

      private

      attr_reader :casing

      def transform_string(str)
        case casing
        when :underscore
          str.underscore
        when :camel
          str.underscore.camelize
        when :lower_camel
          str.underscore.camelize(:lower)
        when :dash
          str.underscore.dasherize
        else
          str
        end
      end

      def transform_key(key)
        case key
        when String
          transform_string(key)
        when Symbol
          transform_string(key.to_s).to_sym
        else
          key
        end
      end

      def transform_value(value)
        case value
        when Hash
          value.deep_transform_keys { transform_key(_1) }
        when Array
          value.map { transform_value(_1) }
        else
          value
        end
      end
    end
  end
end
