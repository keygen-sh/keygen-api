class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    payload = JSONAPI::Serializable::Renderer.render(event, expose: {
      url_helpers: Rails.application.routes.url_helpers
    })

    jid = WebhookWorker.perform_async(
      event.endpoint,
      payload
    )

    event.account.webhook_events.create(
      idempotency_token: event.idempotency_token,
      endpoint: event.endpoint,
      payload: event.payload,
      jid: jid
    )
  rescue Redis::CannotConnectError
    false
  end

  private

  attr_reader :event
end
