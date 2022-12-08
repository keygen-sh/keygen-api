# frozen_string_literal: true

module TypedParameters
  module Controller
    extend ActiveSupport::Concern

    class Handler
      attr_reader :for,
                  :action,
                  :schema,
                  :format

      def initialize(for:, schema:, action: nil, format: nil)
        @for    = binding.local_variable_get(:for)
        @schema = schema
        @action = action
        @format = format
      end

      def action=(action)
        raise ArgumentError, 'cannot redefine action' if
          @action.present?

        @action = action
      end
    end

    included do
      include ClassMethods

      cattr_accessor :typed_handlers, default: { deferred: [], params: {}, query: {} }
      cattr_accessor :typed_schemas,  default: {}

      def typed_params(format: AUTO)
        handler = typed_handlers[:params][action_name.to_sym]

        raise UndefinedActionError, "params have not been defined for action: #{action_name}" if
          handler.nil?

        schema = handler.schema
        params = Parameterizer.new(schema:).call(
          value: request.request_parameters.deep_symbolize_keys,
        )

        Processor.new(controller: self, schema:).call(params)

        case format
        when AUTO
          params.unwrap(formatter: schema.formatter, controller: self)
        when nil
          params.unwrap(formatter: nil, controller: self)
        else
          params.unwrap(formatter: Formatters[format], controller: self)
        end
      end

      def typed_query(format: AUTO)
        handler = typed_handlers[:query][action_name.to_sym]

        raise UndefinedActionError, "query has not been defined for action: #{action_name}" if
          handler.nil?

        schema = handler.schema
        params = Parameterizer.new(schema:).call(
          value: request.query_parameters.deep_symbolize_keys,
        )

        Processor.new(controller: self, schema:).call(params)

        case format
        when AUTO
          params.unwrap(formatter: schema.formatter, controller: self)
        when nil
          params.unwrap(formatter: nil, controller: self)
        else
          params.unwrap(formatter: Formatters[format], controller: self)
        end
      end
    end

    class_methods do
      def typed_params(on: nil, type: :hash, schema: nil, format: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   Schema.new(type:, **kwargs, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers[:params][action] = Handler.new(for: :params, action:, schema:, format:)
          end
        in Symbol => action
          typed_handlers[:params][action] = Handler.new(for: :params, action:, schema:, format:)
        in nil
          typed_handlers[:deferred] << Handler.new(for: :params, schema:, format:)
        end
      end

      def typed_query(on: nil, schema: nil, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   typed_schemas[key] || raise(ArgumentError, "schema does not exist: #{key}")
                 in nil
                   # FIXME(ezekg) Should query params :coerce by default?
                   Schema.new(nilify_blanks: true, **kwargs, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers[:query][action] = Handler.new(for: :query, action:, schema:)
          end
        in Symbol => action
          typed_handlers[:query][action] = Handler.new(for: :query, action:, schema:)
        in nil
          typed_handlers[:deferred] << Handler.new(for: :query, schema:)
        end
      end

      def typed_schema(key, **kwargs, &)
        raise ArgumentError, "schema already exists: #{key}" if
          typed_schemas.key?(key)

        # TODO(ezekg) Implement namespaced schema config? E.g. typed_resource_name:key
        typed_schemas[key] = Schema.new(**kwargs, &)
      end

      private

      def typed_resource_name = controller_name.classify.underscore

      def respond_to_missing?(method_name, *)
        controller_name = self.controller_name.classify.underscore
        aliases         = [
          :"#{controller_name}_params",
          :"#{controller_name}_query",
        ]

        aliases.include?(method_name) || super
      end

      def method_missing(method_name, ...)
        return super unless
          /_(params|query)\z/.match?(method_name) &&
          respond_to?(:controller_name)

        controller_name = self.controller_name&.classify&.underscore
        return super unless
          controller_name.present?

        case method_name
        when :"#{controller_name}_params"
          typed_params(...)
        when :"#{controller_name}_query"
          typed_query(...)
        else
          super
        end
      end

      def method_added(method_name)
        return super if
          typed_handlers[:deferred].empty?

        while handler = typed_handlers[:deferred].shift
          handler.action = method_name

          typed_handlers[handler.for][handler.action] = handler
        end

        super
      end
    end
  end
end
