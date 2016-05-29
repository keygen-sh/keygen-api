# Transform JSON request param keys from JSON-conventional camelCase to
# Rails-conventional snake_case:
#
# @see /config/initializers/json_param_key_transform
# @see /app/controllers/v*/api_controller
# @see /app/serializers/base_serializer
#
ActionDispatch::Request.parameter_parsers[:json] = lambda { |raw_post|
  # Modified from action_dispatch/http/parameters.rb
  data = ActiveSupport::JSON.decode(raw_post)
  data = { _json: data } unless data.is_a?(Hash)

  # Transform camelCase param keys to snake_case:
  data.deep_transform_keys!(&:underscore)
}
