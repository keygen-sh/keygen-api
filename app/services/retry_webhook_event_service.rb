class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def execute
    payload  = JSON.parse event.payload
    endpoint = event.endpoint
    account  = event.account

    jid = WebhookWorker.perform_async(
      account.id,
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
