# frozen_string_literal: true

module TypedParameters
  module ControllerMethods
    extend ActiveSupport::Concern
    extend self

    def typed_parameters(format: nil, &block)
      resource = controller_name.classify.underscore
      method = lambda do
        # TODO(ezekg) Memoize
        validator = Validator.new(request, schema: typed_schema)
        validator.safe_params
      end

      define_method "#{resource}_parameters", &method
      define_method "#{resource}_params", &method

      # TODO(ezekg) Add #{resource}_meta method for JSONAPI
    end
    alias_method :typed_params, :typed_parameters

    def typed_query(&block)
      resource = controller_name.classify.underscore

      define_method "#{resource}_query" do
        validator = Validator.new(request, schema: typed_schema)
        validator.safe_params
      end
    end
  end
end
