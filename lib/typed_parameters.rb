class TypedParameters
  class InvalidParameterError < StandardError
    attr_reader :pointer

    def initialize(pointer:)
      @pointer = { source: "/#{pointer}" }
    end
  end
  class UnpermittedParametersError < StandardError; end
  class InvalidRequestError < StandardError; end
  class Boolean; end

  TRUTHY_VALUES = [true, 1, "1", "true", "TRUE"].freeze

  VALID_TYPES = {
    fixnum: Fixnum,
    number: Numeric,
    integer: Integer,
    float: Float,
    decimal: BigDecimal,
    boolean: Boolean,
    symbol: Symbol,
    string: String,
    hash: Hash,
    array: Array,
    datetime: DateTime,
    date: Date,
    time: Time
  }

  SCALAR_TYPES = VALID_TYPES.slice(
    *(VALID_TYPES.keys - [:hash, :array, :datetime, :date, :time])
  )

  COERCABLE_TYPES = {
    fixnum: lambda { |v| v.to_i },
    number: lambda { |v| v.to_i },
    integer: lambda { |v| v.to_i },
    float: lambda { |v| v.to_f },
    decimal: lambda { |v| v.to_d },
    boolean: lambda { |v| TRUTHY_VALUES.include?(v) },
    symbol: lambda { |v| v.to_sym },
    string: lambda { |v| v.to_s },
    datetime: lambda { |v| v.to_datetime },
    date: lambda { |v| v.to_date },
    time: lambda { |v| v.to_time }
  }

  def self.build(context, &block)
    schema = Schema.new context: context, &block
    handler = schema.handlers[context.action_name]
    handler.call

    # Grab our segment of the params (getting rid of cruft added by Rails middleware)
    # and validate for unpermitted params
    if schema.strict?
      parser = ActionDispatch::Request.parameter_parsers[context.request.format.symbol]
      raise InvalidRequestError, "Request's content type and/or accept headers are unsupported (expected application/vnd.api+json)" if parser.nil?

      segment = parser.call context.request.raw_post
      schema.validate! segment
    end

    schema.params
  end

  private

  class Helper

    def self.deep_keys(o)
      return unless o.respond_to? :each

      if o.is_a? Array
        o.flat_map { |v| deep_keys v }.compact
      else
        o.keys.map(&:to_sym) + o.values.flat_map { |v| deep_keys v }.compact
      end
    end

    def self.compare_types(a, b)
      case class_type(b).to_sym
      when :boolean
        a <= TrueClass || a <= FalseClass
      else
        a <= b
      end
    end

    def self.class_type(c)
      c.name.demodulize.underscore rescue nil
    end
  end

  class Schema
    attr_reader :handlers, :params

    def initialize(context:, stack: [], config: nil, &block)
      @config = config || HashWithIndifferentAccess.new
      @handlers = HashWithIndifferentAccess.new
      @params = HashWithIndifferentAccess.new
      @context = context
      @stack = stack
      @children = []

      self.instance_eval &block
    end

    def strict?
      config.fetch :strict, false
    end

    def validate!(segment = nil)
      return unless strict?

      # Validate nested schemas in reverse order
      children.reverse.map &:validate!

      # Get the difference of current param segment and schema's params
      segment ||= context.params
      unpermitted = segment.keys - params.keys

      raise UnpermittedParametersError, "Unpermitted parameters: #{unpermitted.join ", "}" if unpermitted.any?
    end

    def method_missing(method, *args, &block)
      context.send method, *args, &block
    end

    private

    attr_reader :context, :config, :stack, :children

    def options(opts)
      config.merge! opts
    end

    def on(action, &block)
      handlers.merge! action => block
    end

    # TODO: Write param-level transforms?
    # TODO: Reimplement as/alias option
    def param(key, type:, optional: false, coerce: false, allow_nil: false, inclusion: [], &block)
      real_type = VALID_TYPES.fetch type.to_sym, nil
      keys = stack.dup << key
      value = if context.params.is_a? ActionController::Parameters
                context.params.to_unsafe_h[key]
              else
                context.params[key]
              end

      if coerce && value
        if COERCABLE_TYPES.key?(type.to_sym)
          begin
            value = COERCABLE_TYPES[type.to_sym].call value
          rescue
            raise InvalidParameterError.new(pointer: keys.join("/")), "could not be coerced to #{type}"
          end
        else
          raise InvalidParameterError.new(pointer: keys.join("/")), "could not be coerced (received #{type} expected one of #{COERCABLE_TYPES.keys.join ", "})"
        end
      end

      case
      when real_type.nil?
        raise InvalidParameterError.new(pointer: keys.join("/")), "type is invalid (received #{type} expected one of #{VALID_TYPES.keys.join ", "})"
      when value.nil? && !optional
        raise InvalidParameterError.new(pointer: keys.join("/")), "is missing"
      when !value.nil? && !Helper.compare_types(value.class, real_type)
        raise InvalidParameterError.new(pointer: keys.join("/")), "type mismatch (received #{Helper.class_type(value.class)} expected #{type})"
      when !inclusion.empty? && !inclusion.include?(value)
        raise InvalidParameterError.new(pointer: keys.join("/")), "must be one of: #{inclusion.join ", "} (received #{value})"
      when value.nil? && !allow_nil
        return # We've encountered an optional param (okay to bail early)
      end

      case type.to_sym
      when :hash
        if block_given?
          ctx = context.dup
          ctx.params = value

          child = Schema.new(context: ctx, stack: keys, config: config, &block)
          children << child

          params.merge! key => child.params
        else
          if !value.values.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError.new(pointer: keys.join("/")), "unpermitted type (expected hash of scalar types)"
          end
          params.merge! key => value
        end
      when :array
        if block_given?
          arr_type, b = block.call

          if !value.all? { |v| Helper.compare_types v.class, arr_type }
            raise InvalidParameterError.new(pointer: keys.join("/")), "type mismatch (expected array of #{Helper.class_type(arr_type).pluralize})"
          end

          # TODO: Handle array type here as well
          if Helper.compare_types(arr_type, Hash)
            params.merge! key => value.each_with_index.map { |v, i|
              ctx = context.dup
              ctx.params = v

              child = Schema.new(context: ctx, stack: keys, config: config, &b)
              children << child

              child.params
            }
          else
            params.merge! key => value
          end
        else
          if !value.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError.new(pointer: keys.join("/")), "unpermitted type (expected array of scalar types)"
          end
          params.merge! key => value
        end
      else
        params.merge! key => value
      end
    end

    def items(type:, &block)
      [VALID_TYPES.fetch(type.to_sym, nil), block]
    end
  end

  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      class << self
        def typed_parameters(transform: false, &block)
          resource = controller_name.classify.underscore
          method = lambda do
            @_typed_parameters ||= TypedParameters.build self, &block

            if transform
              _transform_parameters! @_typed_parameters
            else
              @_typed_parameters
            end
          end

          define_method "#{resource}_parameters", &method
          define_method "#{resource}_params", &method
        end
        alias_method :typed_params, :typed_parameters
      end

      private

      def _transform_parameters!(parameters)
        # TODO: Handle meta here as well?
        parameters.inject(HashWithIndifferentAccess.new) do |hash, (_, data)|
          hash.merge! data.slice(:id)
          hash.merge! data.fetch(:attributes, {})
          hash.merge! data.fetch(:relationships, nil)&.map { |key, rel|
            dat = rel.fetch :data, {}

            case dat
            when Array
              _transform_data_array! dat
            when Hash
              _transform_data_hash! dat
            end
          }&.reduce(:merge) || {}
        end
      end

      def _transform_data_array!(datum)
        store = {}

        datum.each do |data|
          type = data.fetch(:type).pluralize

          if data.key? :attributes
            attrs = data.fetch(:attributes, {}).merge data.slice(:id)
            attrs_key = "#{type}_attributes"
            store.key?(attrs_key) ? store[attrs_key] << attrs : store.merge!(attrs_key => [attrs])
          else
            id = data.fetch :id, nil
            id_key = "#{type}_id"
            store.merge! id_key => id if !id.nil?
          end
        end

        store
      end

      def _transform_data_hash!(data)
        store = {}
        type = data.fetch(:type).singularize

        if data.key? :attributes
          attrs = data.fetch(:attributes, {}).merge data.slice(:id)
          attrs_key = "#{type}_attributes"
          store.merge! attrs_key => attrs
        else
          id = data.fetch :id, nil
          id_key = "#{type}_id"
          store.merge! id_key => id if !id.nil?
        end

        store
      end
    end
  end
end
