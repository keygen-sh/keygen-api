# frozen_string_literal: true

require_relative 'transform'

module TypedParameters
  module Transforms
    class KeyCasing < Transform
      def call(key, value)
        transformed_key   = transform(key)
        transformed_value = case value
                            when Hash
                              value.transform_keys! { transform(_1) }
                            when Array
                              value.map { transform(_1) }
                            else
                              value
                            end

        [transformed_key, transformed_value]
      end

      private

      def transform(key)
        case key
        when String
          case TypedParameters.config.key_transform
          when :underscore
            key.underscore
          when :camel
            key.underscore.camelize
          when :lower_camel
            key.underscore.camelize(:lower)
          when :dash
            key.underscore.dasherize
          else
            key
          end
        when Symbol
          transform(key.to_s).to_sym
        when Hash
          key.deep_transform_keys! { transform(_1) }
        when Array
          key.map { transform(_1) }
        else
          key
        end
      end
    end
  end
end
