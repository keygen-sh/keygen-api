class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    account = event.account

    # FIXME(ezekg) Add an association so we don't have to do this stupid lookup
    endpoint = account.webhook_endpoints.find_by url: event.endpoint
    return if endpoint.nil?

    new_event = account.webhook_events.create(
      idempotency_token: event.idempotency_token,
      endpoint: event.endpoint,
      payload: event.payload,
      event: event.event
    )

    payload = JSONAPI::Serializable::Renderer.new.render(new_event, {
      expose: { url_helpers: Rails.application.routes.url_helpers },
      class: {
        Account: SerializableAccount,
        Token: SerializableToken,
        Product: SerializableProduct,
        Policy: SerializablePolicy,
        User: SerializableUser,
        License: SerializableLicense,
        Machine: SerializableMachine,
        Key: SerializableKey,
        Billing: SerializableBilling,
        Plan: SerializablePlan,
        WebhookEndpoint: SerializableWebhookEndpoint,
        WebhookEvent: SerializableWebhookEvent,
        Metric: SerializableMetric,
        Error: SerializableError
      }
    }).to_json

    jid = WebhookWorker.perform_async(
      account.id,
      new_event.id,
      endpoint.id,
      payload
    )

    new_event.update(
      jid: jid
    )

    new_event
  end

  private

  attr_reader :event
end
