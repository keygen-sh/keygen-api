class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    endpoint = event.endpoint
    payload  = event.payload
    account  = event.account

    jid = WebhookWorker.perform_async(
      endpoint,
      payload
    )

    account.webhook_events.create(
      endpoint: endpoint,
      payload: payload,
      jid: jid
    )
  rescue Redis::CannotConnectError
    false
  end

  private

  attr_reader :event
end
