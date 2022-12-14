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
      cattr_accessor :typed_handlers, default: { deferred: [], params: {}, query: {} }
      cattr_accessor :typed_schemas,  default: {}

      def typed_params(format: AUTO)
        handler = typed_handlers.dig(:params, self.class, action_name.to_sym)

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
        handler = typed_handlers.dig(:query, self.class, action_name.to_sym)

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

      private

      def respond_to_missing?(method_name, *)
        return super unless
          /_(params|query)\z/.match?(method_name)

        name = controller_name&.classify&.underscore
        return super unless
          name.present?

        aliases = [
          :"#{name}_params",
          :"#{name}_query",
        ]

        aliases.include?(method_name) || super
      end

      def method_missing(method_name, ...)
        return super unless
          /_(params|query)\z/.match?(method_name)

        name = controller_name&.classify&.underscore
        return super unless
          name.present?

        case method_name
        when :"#{name}_params"
          typed_params(...)
        when :"#{name}_query"
          typed_query(...)
        else
          super
        end
      end
    end

    class_methods do
      def typed_params(on: nil, schema: nil, format: nil, namespace: self, **kwargs, &)
        typed_handlers[:params][self] ||= {}

        schema = case schema
                 in Symbol => key
                   typed_schemas.dig(namespace, key) || raise(ArgumentError, "schema does not exist: #{key.inspect}")
                 in nil
                   Schema.new(**kwargs, controller: self, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers[:params][self][action] = Handler.new(for: :params, action:, schema:, format:)
          end
        in Symbol => action
          typed_handlers[:params][self][action] = Handler.new(for: :params, action:, schema:, format:)
        in nil
          typed_handlers[:deferred] << Handler.new(for: :params, schema:, format:)
        end
      end

      def typed_query(on: nil, schema: nil, namespace: self, **kwargs, &)
        typed_handlers[:query][self] ||= {}

        schema = case schema
                 in Symbol => key
                   typed_schemas.dig(namespace, key) || raise(ArgumentError, "schema does not exist: #{key.inspect}")
                 in nil
                   # FIXME(ezekg) Should query params :coerce by default?
                   Schema.new(nilify_blanks: true, strict: false, **kwargs, controller: self, &)
                 end

        case on
        in Array => actions
          actions.each do |action|
            typed_handlers[:query][self][action] = Handler.new(for: :query, action:, schema:)
          end
        in Symbol => action
          typed_handlers[:query][self][action] = Handler.new(for: :query, action:, schema:)
        in nil
          typed_handlers[:deferred] << Handler.new(for: :query, schema:)
        end
      end

      def typed_schema(key, namespace: self, **kwargs, &)
        typed_schemas[namespace] ||= {}

        raise ArgumentError, "schema already exists: #{key.inspect}" if
          typed_schemas[namespace].key?(key)

        typed_schemas[namespace][key] = Schema.new(**kwargs, controller: self, &)
      end

      private

      def method_added(method_name)
        return super if
          typed_handlers[:deferred].empty?

        while handler = typed_handlers[:deferred].shift
          handler.action = method_name

          typed_handlers[handler.for][self] ||= {}
          typed_handlers[handler.for][self][handler.action] = handler
        end

        super
      end
    end

    def self.included(klass)
      raise ArgumentError, "cannot be used outside of controller (got #{klass.ancestors})" unless
        klass < ::ActionController::Metal

      super(klass)
    end
  end
end
