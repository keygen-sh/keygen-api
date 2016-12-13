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
    number: Numeric,
    integer: Integer,
    float: Float,
    fixnum: Fixnum,
    big_decimal: BigDecimal,
    boolean: Boolean,
    true: TrueClass,
    false: FalseClass,
    symbol: Symbol,
    string: String,
    hash: Hash,
    array: Array,
    null: NilClass,
    nil: NilClass,
    date_time: DateTime,
    date: Date,
    time: Time
  }

  SCALAR_TYPES = VALID_TYPES.slice(
    *(VALID_TYPES.keys - [:hash, :array])
  )

  def self.build(context, &block)
    schema = Schema.new context: context, &block
    handler = schema.handlers[context.action_name]
    params = handler.call

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
      return unless o.respond_to? :keys
      o.keys.map(&:to_sym) + o.values.flat_map { |v| deep_keys v }.compact
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

    def initialize(context:, keys: nil, &block)
      @configuration = HashWithIndifferentAccess.new
      @handlers = HashWithIndifferentAccess.new
      @params = HashWithIndifferentAccess.new
      @context = context
      @keys = keys || []

      self.instance_eval &block
    end

    def strict?
      configuration.fetch :strict, false
    end

    def method_missing(method, *args, &block)
      context.send method, *args, &block
    end

    private

    attr_reader :context, :configuration

    def options(opts)
      configuration.merge! opts
    end

    def on(action, &block)
      handlers.merge! action => block
    end

    def param(name, type:, as: nil, optional: false, allow_nil: false, inclusion: [], &block)
      real_type = VALID_TYPES.fetch type.to_sym, nil
      key = (as || name).to_sym
      value = if context.params.is_a? ActionController::Parameters
                context.params.to_unsafe_h[key]
              else
                context.params[key]
              end

      case
      when real_type.nil?
        raise InvalidParameterError, "Invalid type defined for parameter '#{key}' (received #{type} expected one of #{VALID_TYPES.keys.join ", "})"
      when value.nil? && !optional
        raise InvalidParameterError, "Parameter missing: #{key}"
      when !value.nil? && !Helper.compare_types(value.class, real_type)
        raise InvalidParameterError, "Type mismatch for parameter '#{key}' (received #{Helper.class_type(value.class)} expected #{type})"
      when !inclusion.empty? && !inclusion.include?(value)
        raise InvalidParameterError, "Parameter '#{key}' must be one of: #{inclusion.join ", "} (received #{value})"
      when value.nil? && !allow_nil
        return
      end

      keys << key

      case type.to_sym
      when :hash
        if block_given?
          ctx = context.dup
          ctx.params = value
          params.merge! name => Schema.new(context: ctx, keys: keys, &block).params
        else
          if !value.values.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError, "Unpermitted type found for parameter '#{key}' (expected hash of scalar types)"
          end
          value.keys.each { |k| keys << k.to_sym }
          params.merge! name => value
        end
      when :array
        if block_given?
          arr_type = block.call

          if !value.all? { |v| Helper.compare_types v.class, arr_type }
            raise InvalidParameterError, "Type mismatch for parameter '#{key}' (expected array of #{Helper.class_type(arr_type).pluralize})"
          end
        else
          if !value.all? { |v| SCALAR_TYPES[Helper.class_type(v.class).to_sym] }
            raise InvalidParameterError, "Unpermitted type found for parameter '#{key}' (expected array of scalar types)"
          end
        end
        params.merge! name => value
      else
        params.merge! name => value
      end
    end

    def items(type:)
      VALID_TYPES.fetch type.to_sym, nil
    end
  end

  class InvalidParameterError < StandardError; end
end
