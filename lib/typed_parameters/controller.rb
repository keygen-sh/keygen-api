# frozen_string_literal: true

module TypedParameters
  module Controller
    extend ActiveSupport::Concern

    class Handler
      attr_reader :action,
                  :schema,
                  :format

      def initialize(action:, schema:, format: nil)
        @action = action
        @schema = schema
        @format = format
      end
    end

    included do
      include ClassMethods

      cattr_accessor :typed_handlers, default: {}
      cattr_accessor :typed_schemas,  default: {}

      def typed_params
        input   = params.to_unsafe_h.except(:controller, :action, :format)
        handler = typed_handlers[:"params:#{action_name}"]
        schema  = handler.schema
        params  = Parameterizer.new(schema:).call(value: input)

        Processor.new(schema:).call(params)

        params.safe
      end

      def typed_query
        input   = params.to_unsafe_h.except(:controller, :action, :format)
        handler = typed_handlers[:"query:#{action_name}"]
        schema  = handler.schema
        params  = Parameterizer.new(schema:).call(value: input)

        Processor.new(schema:).call(params)

        params.safe
      end

      def respond_to_missing?(method_name, *)
        controller_name = self.controller_name.classify.underscore
        aliases         = [
          :"#{controller_name}_params",
          :"#{controller_name}_query",
        ]

        aliases.include?(method_name) || super
      end

      def method_missing(method_name, *)
        return super unless
          /_(params|query)\z/.match?(method_name) &&
          respond_to?(:controller_name)

        controller_name = self.controller_name&.classify&.underscore
        return super unless
          controller_name.present?

        case method_name
        when :"#{controller_name}_params"
          typed_params
        when :"#{controller_name}_query"
          typed_query
        else
          super
        end
      end
    end

    class_methods do
      # TODO(ezekg) Add implicit and explicit param definitions via decorator queue
      def typed_params(on:, type: :hash, schema: nil, format: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   Schema.new(type:, **kwargs, &)
                 end

        typed_handlers[:"params:#{on}"] = Handler.new(action: on, schema:, format:)
      end

      def typed_query(on:, schema: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   Schema.new(nilify_blanks: true, **kwargs, &)
                 end

        typed_handlers[:"query:#{on}"] = Handler.new(action: on, schema:)
      end

      def typed_schema(key, **kwargs, &)
        raise ArgumentError, "schema already exists: #{key}" if
          typed_schemas.key?(key)

        # TODO(ezekg) Implement namespaced schema config? E.g. typed_resource_name:key
        typed_schemas[key] = Schema.new(**kwargs, &)
      end

      private

      def typed_resource_name = controller_name.classify.underscore
    end
  end
end
