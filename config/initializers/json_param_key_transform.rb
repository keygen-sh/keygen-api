# Transform JSON request param keys from JSON-conventional camelCase to
# Rails-conventional snake_case
ActionDispatch::Request.parameter_parsers[:json] = lambda { |raw_post|
  # Modified from action_dispatch/http/parameters.rb
  data = ActiveSupport::JSON.decode raw_post
  data = { _json: data } unless data.is_a?(Hash)

  # Transform camelCase param keys to snake_case:
  data.deep_transform_keys! &:underscore
}
