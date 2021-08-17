# frozen_string_literal: true

class TypedParameters
  class InvalidParameterError < StandardError
    attr_reader :source

    def initialize(type:, param:)
      @source =
        case type
        when :parameter
          { parameter: "#{param}" }
        when :pointer
          { pointer: "/#{param}" }
        else
          nil
        end
    end
  end
  class UnpermittedParametersError < StandardError; end
  class InvalidRequestError < StandardError; end
  class Boolean; end

  TRUTHY_VALUES = [true, 1, "1", "true", "TRUE"].freeze

  VALID_TYPES = {
    number: Numeric,
    integer: Integer,
    float: Float,
    decimal: BigDecimal,
    true_class: TrueClass,
    false_class: FalseClass,
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
    schema = Schema.new controller: context, context: context, &block
    handler = schema.handlers[context.action_name]
    handler.call

    # Grab our segment of the params (getting rid of cruft added by Rails middleware)
    # and validate for unpermitted params
    if schema.strict?
      parser = ActionDispatch::Request.parameter_parsers[:jsonapi]
      raise InvalidRequestError, "content-type and/or accept headers are unsupported (expected application/vnd.api+json)" if
        parser.nil?

      body = context.request.raw_post
      body = '{}' unless
        body.present?

      segment = parser.call body
      schema.validate! segment
    end
    schema.transform!

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
      t = c.name.demodulize.underscore.to_sym rescue nil

      # Rename hash => object for easier debugging (since most languages call a hash type an "object" or "dictionary")
      t = :object if t == :hash || t == :hash_with_indifferent_access

      t.to_s
    end
  end

  class Schema
    attr_reader :controller, :handlers, :params

    def initialize(controller:, context:, stack: [], config: nil, &block)
      @config = config || HashWithIndifferentAccess.new
      @handlers = HashWithIndifferentAccess.new
      @params = HashWithIndifferentAccess.new
      @transforms = HashWithIndifferentAccess.new
      @controller = controller
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
      keys = segment.keys - params.keys
      unpermitted = keys.map { |k| k.to_s.camelize :lower }.join ", "

      Keygen.logger.error("[typed_parameters] Unpermitted parameters: request_id=#{context.request.request_id} unpermitted=(#{unpermitted})")
      Keygen.logger.error(segment: segment, segment_keys: segment.keys, params_keys: params.keys)

      raise UnpermittedParametersError, "Unpermitted parameters: #{unpermitted}" if keys.any?
    end

    def transform!
      # Transform nested schemas in reverse order
      children.reverse.map &:transform!

      return if transforms.empty?

      # NOTE: Transforms must return a tuple
      transforms.each { |key, transform|
        value = params.delete key
        k, v = transform.call key, value
        next if k.nil?

        params[k] = v
      }
    end

    def method_missing(method, *args, &block)
      controller.send method, *args, &block
    end

    private

    attr_reader :context, :config, :stack, :children, :transforms

    def options(opts)
      config.merge! opts
    end

    def on(action, &block)
      handlers.merge! action => block
    end

    def param(key, type:, optional: false, coerce: false, allow_blank: true, allow_nil: false, allow_non_scalars: false, inclusion: [], transform: nil, source: :pointer, &block)
      return if optional && !context.params.key?(key.to_s)

      real_type = VALID_TYPES.fetch type.to_sym, nil
      value = if context.params.is_a? ActionController::Parameters
                context.params.to_unsafe_h[key]
              else
                context.params[key]
              end

      if value.nil? && optional && !allow_nil
        [key.to_s, key.to_s.camelize(:lower)].map { |k| context.params.delete k }
        return
      end

      keys = stack.dup << key.to_s.camelize(:lower)

      if coerce && value
        if COERCABLE_TYPES.key?(type.to_sym)
          begin
            value = COERCABLE_TYPES[type.to_sym].call value
          rescue
            raise InvalidParameterError.new(type: source, param: keys.join("/")), "could not be coerced"
          end
        else
          raise InvalidParameterError.new(type: source, param: keys.join("/")), "could not be coerced (expected one of #{COERCABLE_TYPES.keys.join ", "})"
        end
      end

      case
      when real_type.nil?
        raise InvalidParameterError.new(type: source, param: keys.join("/")), "type is invalid (expected one of #{VALID_TYPES.keys.join ", "})"
      when value.nil? && !optional && !allow_nil
        raise InvalidParameterError.new(type: source, param: keys.join("/")), "is missing"
      when !value.nil? && !Helper.compare_types(value.class, real_type)
        raise InvalidParameterError.new(type: source, param: keys.join("/")), "type mismatch (received #{Helper.class_type(value.class)} expected #{Helper.class_type(real_type)})"
      when !value.nil? && !inclusion.empty? && !inclusion.include?(value)
        raise InvalidParameterError.new(type: source, param: keys.join("/")), "must be one of: #{inclusion.join ", "} (received #{value})"
      when value.blank? && !allow_blank
        raise InvalidParameterError.new(type: source, param: keys.join("/")), "cannot be blank"
      end

      transforms.merge! key => transform if transform.present?

      if value.nil? && allow_nil
        params.merge! key => value
        return
      end

      case type.to_sym
      when :hash
        if block_given?
          ctx = context.dup
          ctx.params = value

          child = Schema.new(controller: context, context: ctx, stack: keys, config: config, &block)
          children << child

          params.merge! key => child.params
        else
          if !value.values.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            if allow_non_scalars
              value.each do |k, v|
                next if SCALAR_TYPES[Helper.class_type(v.class).to_sym].present?

                keys << k.to_s.camelize(:lower)

                # FIXME(ezekg) This is very, very dirty…
                case v
                when Hash
                  v.each do |k, v|
                    next if SCALAR_TYPES[Helper.class_type(v.class).to_sym].present?

                    raise InvalidParameterError.new(type: source, param: (keys << k.to_s.camelize(:lower)).join("/")), "unpermitted type (expected nested object of scalar types)"
                  end
                when Array
                  v.each_with_index do |v, i|
                    next if SCALAR_TYPES[Helper.class_type(v.class).to_sym].present?

                    raise InvalidParameterError.new(type: source, param: (keys << i).join("/")), "unpermitted type (expected nested array of scalar types)"
                  end
                end
              end
            else
              raise InvalidParameterError.new(type: source, param: keys.join("/")), "unpermitted type (expected object of scalar types)"
            end
          end

          params.merge! key => value
        end
      when :array
        if block_given?
          arr_type, b = block.call

          if index = value.index { |v| !Helper.compare_types(v.class, arr_type) }
            keys << index

            raise InvalidParameterError.new(type: source, param: keys.join("/")), "type mismatch (expected array of #{Helper.class_type(arr_type).pluralize})"
          end

          # TODO: Handle array type here as well
          if Helper.compare_types(arr_type, Hash)
            params.merge! key => value.each_with_index.map { |v, i|
              ctx = context.dup
              ctx.params = v

              child = Schema.new(controller: context, context: ctx, stack: [*keys, i], config: config, &b)
              children << child

              child.params
            }
          else
            params.merge! key => value
          end
        else
          if index = value.index { |v| !SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            keys << index

            raise InvalidParameterError.new(type: source, param: keys.join("/")), "unpermitted type (expected array of scalar types)"
          end
          params.merge! key => value
        end
      else
        params.merge! key => value
      end
    end

    def query(key, **kwargs, &block)
      param(key, **kwargs.merge(source: :parameter))
    end

    def items(type:, &block)
      [VALID_TYPES.fetch(type.to_sym, nil), block]
    end
  end

  module ControllerMethods
    extend ActiveSupport::Concern

    included do
      class << self
        def typed_parameters(format: nil, &block)
          resource = controller_name.classify.underscore
          method = lambda do
            @_typed_parameters ||= TypedParameters.build self, &block

            if format == :jsonapi
              deserialize_jsonapi_parameters(@_typed_parameters)
            else
              @_typed_parameters
            end
          end

          define_method "#{resource}_parameters", &method
          define_method "#{resource}_params", &method

          define_method "#{resource}_meta" do
            @_typed_parameters ||= TypedParameters.build self, &block

            @_typed_parameters.fetch(:meta, {})
          end
        end
        alias_method :typed_params, :typed_parameters

        def typed_query(&block)
          resource = controller_name.classify.underscore

          define_method "#{resource}_query" do
            @_typed_query ||= TypedParameters.build self, &block
          end
        end
      end

      private

      def deserialize_jsonapi_parameters(parameters)
        transformer = -> (params, data) {
          params.merge! data.slice(:id)
          params.merge! data.fetch(:attributes, {})
          params.merge! data.fetch(:relationships, nil)&.map { |key, rel|
            d = rel.fetch(:data, nil)

            deserialize_jsonapi_data(d)
          }&.compact&.reduce(:merge) || {}
        }

        # TODO(ezekg) Handle meta here as well?
        parameters.inject(HashWithIndifferentAccess.new) do |params, (_, data)|
          case data
          when Array
            data.map { |d| transformer.call(params.dup, d) }
          when Hash
            transformer.call(params, data)
          end
        end
      end

      def deserialize_jsonapi_data_array(datum)
        store = {}

        datum.each do |data|
          type = data.fetch(:type).pluralize.underscore

          case
          when data.key?(:relationships),
               data.key?(:attributes)
            id    = data.slice(:id)
            attrs = data.fetch(:attributes, {})
            rels  = data.fetch(:relationships, {}).map { |key, rel|
              d = rel.fetch :data, nil

              deserialize_jsonapi_data(d)
            }.compact.reduce(:merge) || {}

            assoc_key   = "#{type}_attributes"
            assoc_attrs = {}.merge(id, attrs, rels)

            if store.key?(assoc_key)
              store[assoc_key] << assoc_attrs
            else
              store.merge!(assoc_key => [assoc_attrs])
            end
          else
            ids_key = "#{type}_ids"
            id = data.fetch(:id, nil)

            if store.key?(ids_key)
              store[ids_key] << id
            else
              store.merge!(ids_key => [id])
            end
          end
        end

        store
      end

      def deserialize_jsonapi_data_hash(data)
        store = {}
        type = data.fetch(:type).singularize.underscore

        case
        when data.key?(:relationships),
             data.key?(:attributes)
          id    = data.slice(:id)
          attrs = data.fetch(:attributes, {})
          rels  = data.fetch(:relationships, {}).map { |key, rel|
            d = rel.fetch(:data, nil)

            deserialize_jsonapi_data(d)
          }.compact.reduce(:merge) || {}

          assoc_key   = "#{type}_attributes"
          assoc_attrs = {}.merge(id, attrs, rels)

          store.merge!(assoc_key => assoc_attrs)
        else
          id_key = "#{type}_id"
          id = data.fetch(:id, nil)

          store.merge!(id_key => id) unless
            id.nil?
        end

        store
      end

      def deserialize_jsonapi_data(data)
        case data
        when Array
          deserialize_jsonapi_data_array(data)
        when Hash
          deserialize_jsonapi_data_hash(data)
        else
          nil
        end
      end
    end
  end
end
