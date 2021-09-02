# frozen_string_literal: true

# Register JSON API mime-type
Mime::Type.register "application/vnd.api+json", :jsonapi, %W[
  application/vnd.keygen+json
  application/vnd.api+json
  application/json
]

# Register parameter parser for JSON API mime-type to transform param keys from
# camel case to snake case
ActionDispatch::Request.parameter_parsers[:json]    =
ActionDispatch::Request.parameter_parsers[:jsonapi] = -> raw_post {
  data = ActiveSupport::JSON.decode(raw_post)

  raise JSON::ParserError, 'expected top-level object' unless
    data.is_a?(Hash)

  data.deep_transform_keys! { |k| k.to_s.underscore.parameterize(separator: '_') }

  data.with_indifferent_access
}

JSONAPI::Rails.configure do |config|
  logger       = Logger.new(STDOUT)
  logger.level = Logger::WARN

  # Dynamic serializer class resolver
  config.jsonapi_class  = -> klass { "#{klass}Serializer".safe_constantize }
  config.jsonapi_object = nil
  config.logger         = logger
end
