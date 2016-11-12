# TypedParameters.build context do
#   options strict: true
#
#   on :create do
#     param :license, type: Hash do
#       param :policy, type: String
#       param :user, type: String, optional: true
#       param :role_attributes, type: Hash, as: :role do
#         param :name, type: Integer
#       end
#       param :array, type: Array do
#         item type: Integer
#       end
#       param :hash, type: Hash
#     end
#   end
#
#   on :update do
#     param :license, type: Hash do
#       param :policy, type: String
#     end
#   end
# end
class TypedParameters
  IGNORED_KEYS = [:controller, :action].freeze

  def self.build(context, &block)
    schema = Schema.new context, &block
    handler = schema.handlers[context.action_name]
    params = handler.call

    if schema.strict?
      # Grab our segment of the params (getting rid of cruft added by Rails middleware)
      params_slice = context.params.slice *params.keys
      # Get deep array keys and calc the difference when compared to our parsed keys
      unpermiited = deep_keys(params_slice) - schema.keys

      raise InvalidParameterError, "Unpermitted parameters: #{unpermiited.join ", "}" if unpermiited.any?
    end

    params
  end

  private

  def self.deep_keys(obj)
    return unless obj.respond_to? :keys
    obj.keys.map(&:to_sym) + obj.values.flat_map { |v| deep_keys v }.compact
  end

  class Schema
    attr_reader :handlers, :params, :keys

    def initialize(context, keys = nil, &block)
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

    def method_missing(method)
      context.send method
    end

    private

    attr_reader :context, :configuration

    def options(opts)
      configuration.merge! opts
    end

    def on(action, &block)
      handlers.merge! action => block
    end

    def param(name, type:, as: nil, optional: false, allow_nil: false, &block)
      key = (as || name).to_sym
      value = if context.params.is_a? ActionController::Parameters
                context.params.to_unsafe_h[key]
              else
                context.params[key]
              end

      case
      when value.nil? && !optional
        raise InvalidParameterError, "Parameter missing: #{key}"
      when !value.nil? && !(value.class <= type)
        raise InvalidParameterError, "Type mismatch for #{key} (expected #{type.name.underscore} got #{value.class.name.underscore})"
      when value.nil? && !allow_nil
        return
      end

      keys << key

      case type.name.downcase.to_sym
      when :hash
        if block_given?
          ctx = context.dup
          ctx.params = value
          params.merge! name => Schema.new(ctx, keys, &block).params
        else
          value.keys.each { |k| keys << k.to_sym }
          params.merge! name => value
        end
      when :array
        if block_given?
          arr_type = block.call

          if !value.all? { |v| v.class <= arr_type }
            raise InvalidParameterError, "Type mismatch for #{key} (expected array of #{arr_type.name.underscore.pluralize})"
          end
        end
        params.merge! name => value
      else
        params.merge! name => value
      end
    end

    def item(type:)
      type
    end
  end

  class InvalidParameterError < StandardError; end
end

# FIXME: Need to figure out a way to create a boolean type that isn't global
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end
