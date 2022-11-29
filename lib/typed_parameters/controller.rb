# frozen_string_literal: true

module TypedParameters
  module Controller
    extend ActiveSupport::Concern

    included do
      cattr_accessor :typed_handlers, default: {}
      cattr_accessor :typed_schemas,  default: {}

      include ClassMethods
    end

    private

    module ClassMethods
      # TODO(ezekg) Add implicit and explicit param definitions via decorator queue
      def typed_parameters(on:, type: :hash, schema: nil, format: nil, **kwargs, &block)
        typed_handlers[:"params:#{on}"] = [kwargs, block]

        method = lambda do
          v = params.to_unsafe_h.symbolize_keys.except(:controller, :action, :format)
          s = case schema
              in Symbol => key
                kw, b = typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")

                Schema.new(type:, **kw, &b)
              in nil
                kw, b = typed_handlers[:"params:#{action_name}"]

                Schema.new(type:, **kw, &b)
              end

          p = Parameterizer.new(schema: s).call(value: v)

          Processor.new(schema: s).call(p)

          p.safe
        end

        define_method "#{typed_resource_name}_parameters", &method
        define_method "#{typed_resource_name}_params", &method

        case format
        when :jsonapi
          # FIXME(ezekg) Move to JSONAPI formatter?
          # TODO(ezekg) Implement resource_meta method for JSONAPI
          define_method "#{typed_resource_name}_meta" do
            {}
          end
        end
      end
      alias_method :typed_params, :typed_parameters

      def typed_query(on:, schema: nil, **kwargs, &block)
        typed_handlers[:"query:#{on}"] = [kwargs, block]

        define_method "#{typed_resource_name}_query" do
          v = params.to_unsafe_h.symbolize_keys.except(:controller, :action, :format)
          s = case schema
              in Symbol => key
                kw, b = typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")

                Schema.new(**kw, &b)
              in nil
                kw, b = typed_handlers[:"query:#{action_name}"]

                Schema.new(nilify_blanks: true, **kw, &b)
              end

          p = Parameterizer.new(schema: s).call(value: v)

          Processor.new(schema: s).call(p)

          p.safe
        end
      end

      def typed_schema(key, **kwargs, &block)
        raise ArgumentError, "schema already exists: #{key}" if
          typed_schemas.key?(key)

        # TODO(ezekg) Implement namespaced schema config? E.g. typed_resource_name:key
        typed_schemas[key] = [kwargs, block]
      end

      private

      def typed_resource_name = controller_name.classify.underscore
    end
  end
end
