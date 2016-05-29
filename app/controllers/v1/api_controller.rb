module V1
  class ApiController < ApplicationController
    include ActionController::Serialization

    # Transform JSON response keys from Rails-conventional snake_case to
    # JSON-conventional camelCase. This does not modify models; that
    # should be done with a serializer. See the base serializer
    # for more info.
    #
    # @see /config/initializers/json_param_key_transform
    # @see /app/controllers/api/v*/api_controller
    # @see /app/serializers/base_serializer
    #
    def render(*args)
      if args.first[:json].class == Hash
        args.first[:json].deep_transform_keys! do |k|
          k.to_s.camelize(:lower).to_sym
        end
      end
      super
    end
  end
end
