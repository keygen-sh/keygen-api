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
        schema = case schema
                 in Symbol => key
                   namespaced_key = [*namespace, key].join('/')
                                                     .to_sym

                   typed_schemas[namespaced_key] || raise(ArgumentError, "schema does not exist: #{namespaced_key.inspect}")
                 in nil
                   Schema.new(**kwargs, controller: self, &)
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

      def typed_query(on: nil, schema: nil, namespace: self, **kwargs, &)
        schema = case schema
                 in Symbol => key
                   namespaced_key = [*namespace, key].join('/')
                                                     .to_sym

                   typed_schemas[namespaced_key] || raise(ArgumentError, "schema does not exist: #{namespaced_key.inspect}")
                 in nil
                   # FIXME(ezekg) Should query params :coerce by default?
                   Schema.new(nilify_blanks: true, strict: false, **kwargs, controller: self, &)
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

      def typed_schema(key, namespace: self, **kwargs, &)
        namespaced_key = [*namespace, key].join('/')
                                          .to_sym

        raise ArgumentError, "schema already exists: #{namespaced_key.inspect}" if
          typed_schemas.key?(namespaced_key)

        typed_schemas[namespaced_key] = Schema.new(**kwargs, controller: self, &)
      end

      private

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

    def self.included(klass)
      raise ArgumentError, "cannot be used outside of controller (got #{klass.ancestors})" unless
        klass < ::ActionController::Metal

      super(klass)
    end
  end
end
