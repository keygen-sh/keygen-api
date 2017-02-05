class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    webhook_event = event.account.webhook_events.create(
      idempotency_token: event.idempotency_token,
      endpoint: event.endpoint,
      payload: event.payload,
      event: event.event
    )

    payload = JSONAPI::Serializable::Renderer.render(webhook_event, expose: {
      url_helpers: Rails.application.routes.url_helpers
    })

    jid = WebhookWorker.perform_async(
      event.endpoint,
      payload
    )

    webhook_event.update(
      jid: jid
    )

    webhook_event
  rescue Redis::CannotConnectError
    false
  end

  private

  attr_reader :event
end
