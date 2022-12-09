# frozen_string_literal: true

module TypedParameters
  class Path
    attr_reader :keys

    def initialize(*keys) = @keys = keys

    def to_json_pointer = '/' + keys.map { transform(_1) }.join('/')
    def to_dot_notation = keys.map { transform(_1) }.join('.')

    def to_s
      keys.map { transform(_1) }.reduce(+'') do |s, key|
        next s << key if s.blank?

        case key
        when Numeric
          s << "[#{key}]"
        else
          s << ".#{key}"
        end
      end
    end

    def inspect
      "#<#{self.class.name}: #{to_s.inspect}>"
    end

    private

    def transform(key)
      return key if key.is_a?(Numeric)

      case TypedParameters.config.path_transform
      when :underscore
        key.to_s.underscore
      when :camel
        key.to_s.underscore.camelize
      when :lower_camel
        key.to_s.underscore.camelize(:lower)
      when :dash
        key.to_s.underscore.dasherize
      else
        key.to_s
      end
    end
  end
end
