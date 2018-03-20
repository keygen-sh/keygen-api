class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    account = event.account
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
        Role: SerializableRole,
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

    jid = SignedWebhookWorker.perform_async(
      account.id,
      new_event.id,
      payload
    )

    new_event.update(
      jid: jid
    )

    new_event
  rescue Redis::CannotConnectError
    false
  end

  private

  attr_reader :event
end
