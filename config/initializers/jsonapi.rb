# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  SERIALIZABLE_CLASSES = {
    Account: SerializableAccount,
    Billing: SerializableBilling,
    Entitlement: SerializableEntitlement,
    Error: SerializableError,
    Key: SerializableKey,
    LicenseEntitlement: SerializableLicenseEntitlement,
    License: SerializableLicense,
    Machine: SerializableMachine,
    Metric: SerializableMetric,
    Plan: SerializablePlan,
    PolicyEntitlement: SerializablePolicyEntitlement,
    Policy: SerializablePolicy,
    Product: SerializableProduct,
    Release: SerializableRelease,
    RequestLog: SerializableRequestLog,
    SecondFactor: SerializableSecondFactor,
    Token: SerializableToken,
    User: SerializableUser,
    WebhookEndpoint: SerializableWebhookEndpoint,
    WebhookEvent: SerializableWebhookEvent,
  }
end

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
  data.deep_transform_keys! { |k| k.to_s.underscore.parameterize(separator: '_') }
  data.with_indifferent_access
}

# Update jsonapi-rails configuration to not render jsonapi version
JSONAPI::Rails.configure do |config|
  config.jsonapi_object = nil
end
