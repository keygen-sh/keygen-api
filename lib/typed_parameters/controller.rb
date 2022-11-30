# frozen_string_literal: true

module TypedParameters
  module Controller
    extend ActiveSupport::Concern

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

      class_eval <<~RUBY
        alias_method :#{controller_name.classify.underscore}_params, :typed_params
        alias_method :#{controller_name.classify.underscore}_query,  :typed_query
      RUBY
    end

    class_methods do
      Handler = Struct.new(:type, :schema, :format, keyword_init: true)

      # TODO(ezekg) Add implicit and explicit param definitions via decorator queue
      def typed_params(on:, type: :hash, schema: nil, format: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   Schema.new(type:, **kwargs, &)
                 end

        typed_handlers[:"params:#{on}"] = Handler.new(type:, schema:, format:)
      end

      def typed_query(on:, schema: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   Schema.new(nilify_blanks: true, **kwargs, &)
                 end

        typed_handlers[:"query:#{on}"] = Handler.new(type:, schema:, format:)
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
