# Register JSON API mime-type
Mime::Type.register "application/vnd.api+json", :jsonapi, %W[
  application/vnd.keygen+json
  application/vnd.api+json
  application/json
  text/x-json
]


# Register parameter parser for JSON API mime-type to transform param keys from
# camel case to snake case
ActionDispatch::Request.parameter_parsers[:json]    =
ActionDispatch::Request.parameter_parsers[:jsonapi] = -> (raw_post) {
  data = ActiveSupport::JSON.decode raw_post
  data = { _json: data } unless data.is_a? Hash
  data.deep_transform_keys! &:underscore
  data.with_indifferent_access
}

# Make sure jsonapi/rails doesn't overwrite our registrations
JSONAPI::Rails.configure do |config|
  config.register_parameter_parser = false
  config.register_mime_type = false
end
