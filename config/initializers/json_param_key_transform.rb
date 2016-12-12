# Transform JSON request param keys from camelCase to snake_case

# Modified from action_dispatch/http/parameters.rb
parser = -> (raw_post) {
  data = ActiveSupport::JSON.decode raw_post
  data = { _json: data } unless data.is_a? Hash
  data.deep_transform_keys! &:underscore
  data.with_indifferent_access
}

# Redefine parameter parser for JSON mime-type
ActionDispatch::Request.parameter_parsers[:json] = parser

# Redefine parameter parser for JSONAPI mime-type
JSONAPI::Rails::Railtie::PARSER = parser
