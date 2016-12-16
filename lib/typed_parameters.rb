# TypedParameters.build context do
#   options strict: true
#
#   on :create do
#     param :license, type: :hash do
#       param :policy, type: :string
#       param :user, type: :string, optional: true
#       param :role_attributes, type: :hash, as: :role do
#         param :name, type: :integer
#       end
#       param :array, type: :array do
#         items type: :integer
#       end
#       param :hash, type: :hash
#     end
#   end
#
#   on :update do
#     param :license, type: :hash do
#       param :policy, type: :string
#     end
#   end
# end
class TypedParameters
  class Boolean; end

  VALID_TYPES = {
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
    integer: lambda { |v| v.to_i },
    float: lambda { |v| v.to_f },
    decimal: lambda { |v| v.to_d },
    boolean: lambda { |v| !!v },
    symbol: lambda { |v| v.to_sym },
    string: lambda { |v| v.to_s },
    datetime: lambda { |v| v.to_datetime },
    date: lambda { |v| v.to_date },
    time: lambda { |v| v.to_time }
  }

  def self.build(context, &block)
    schema = Schema.new context: context, &block
    handler = schema.handlers[context.action_name]
    params = handler.call

    # TODO: This needs to do a real comparison of schemas, not simply allowed
    #       keys like it's doing now.
    if schema.strict?
      # Grab our segment of the params (getting rid of cruft added by Rails middleware)
      params_slice = context.params.slice *params.keys
      # Get deep array keys and calc the difference when compared to our parsed keys
      unpermitted = Helper.deep_keys(params_slice) - schema.keys

      raise InvalidParameterError, "Unpermitted parameters: #{unpermitted.join ", "}" if unpermitted.any?
    end

    params
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
    attr_reader :handlers, :params, :keys

    def initialize(context:, stack: [], keys: [], &block)
      @configuration = HashWithIndifferentAccess.new
      @handlers = HashWithIndifferentAccess.new
      @params = HashWithIndifferentAccess.new
      @context = context
      @stack = stack
      @keys = keys

      self.instance_eval &block
    end

    def strict?
      configuration.fetch :strict, false
    end

    def method_missing(method, *args, &block)
      context.send method, *args, &block
    end

    private

    attr_reader :context, :configuration, :stack

    def options(opts)
      configuration.merge! opts
    end

    def on(action, &block)
      handlers.merge! action => block
    end

    def param(name, type:, as: nil, optional: false, coerce: false, allow_nil: false, inclusion: [], &block)
      real_type = VALID_TYPES.fetch type.to_sym, nil
      key = (as || name).to_sym
      stack_keys = stack.dup << key
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
            raise InvalidParameterError, "Parameter '#{stack_keys.join "."}' could not be coerced to #{type}"
          end
        else
          raise InvalidParameterError, "Invalid type for coercion (received #{type} expected one of #{COERCABLE_TYPES.keys.join ", "})"
        end
      end

      case
      when real_type.nil?
        raise InvalidParameterError, "Invalid type defined for parameter '#{stack_keys.join "."}' (received #{type} expected one of #{VALID_TYPES.keys.join ", "})"
      when value.nil? && !optional
        raise InvalidParameterError, "Parameter missing: #{stack_keys.join "."}"
      when !value.nil? && !Helper.compare_types(value.class, real_type)
        raise InvalidParameterError, "Type mismatch for parameter '#{stack_keys.join "."}' (received #{Helper.class_type(value.class)} expected #{type})"
      when !inclusion.empty? && !inclusion.include?(value)
        raise InvalidParameterError, "Parameter '#{stack_keys.join "."}' must be one of: #{inclusion.join ", "} (received #{value})"
      when value.nil? && !allow_nil
        return # We've encountered an optional param (okay to bail early)
      end

      keys << key

      case type.to_sym
      when :hash
        if block_given?
          ctx = context.dup
          ctx.params = value
          params.merge! name => Schema.new(context: ctx, stack: stack_keys, keys: keys, &block).params
        else
          if !value.values.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError, "Unpermitted type found for parameter '#{stack_keys.join "."}' (expected hash of scalar types)"
          end
          value.keys.each { |k| keys << k.to_sym }
          params.merge! name => value
        end
      when :array
        if block_given?
          arr_type, b = block.call

          if !value.all? { |v| Helper.compare_types v.class, arr_type }
            raise InvalidParameterError, "Type mismatch for parameter '#{stack_keys.join "."}' (expected array of #{Helper.class_type(arr_type).pluralize})"
          end

          if Helper.compare_types(arr_type, Hash)
            params.merge! name => value.each_with_index.map { |v, i|
              ctx = context.dup
              ctx.params = v
              Schema.new(context: ctx, stack: stack_keys, keys: keys, &b).params
            }
          else
            params.merge! name => value
          end
        else
          if !value.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError, "Unpermitted type found for parameter '#{stack_keys.join "."}' (expected array of scalar types)"
          end
          params.merge! name => value
        end
      else
        params.merge! name => value
      end
    end

    def items(type:, &block)
      [VALID_TYPES.fetch(type.to_sym, nil), block]
    end
  end

  class InvalidParameterError < StandardError; end

  module ControllerMethods
    extend ActiveSupport::Concern

    included do

      class << self
        def typed_parameters(transform: false, &block)
          model = controller_name.classify.underscore
          method = lambda do
            @_typed_parameters ||= TypedParameters.build self, &block

            if transform
              _transform_parameters! @_typed_parameters
            else
              @_typed_parameters
            end
          end

          define_method "#{model}_parameters", &method
          define_method "#{model}_params", &method
        end
        alias_method :typed_params, :typed_parameters
      end

      private

      def _transform_parameters!(parameters)
        parameters.inject({}) do |hash, (_, data)|
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
