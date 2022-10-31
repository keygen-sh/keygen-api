# frozen_string_literal: true

module TypedParameters
  module ControllerMethods
    extend ActiveSupport::Concern
    extend self

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
end
