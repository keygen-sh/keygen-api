# frozen_string_literal: true

module TypedParameters
  class Path
    attr_reader :keys

    def initialize(*keys, casing: nil)
      @casing = casing || TypedParameters.config.path_transform
      @keys   = keys
    end

    def to_json_pointer = '/' + keys.map { transform_key(_1) }.join('/')
    def to_dot_notation = keys.map { transform_key(_1) }.join('.')

    def to_s
      keys.map { transform_key(_1) }.reduce(+'') do |s, key|
        next s << key if s.blank?

        case key
        when Integer
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
      return key if key.is_a?(Integer)

      transform_string(key.to_s)
    end
  end
end
