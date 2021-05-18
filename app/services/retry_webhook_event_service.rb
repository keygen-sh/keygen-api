# frozen_string_literal: true

class RetryWebhookEventService < BaseService

  def initialize(event:)
    @event = event
  end

  def call
    account = event.account

    # FIXME(ezekg) Add an association so we don't have to do this stupid lookup
    endpoint = account.webhook_endpoints.find_by url: event.endpoint
    return if endpoint.nil?

    new_event = account.webhook_events.create(
      idempotency_token: event.idempotency_token,
      endpoint: event.endpoint,
      payload: event.payload,
      event_type: event.event_type
    )

    payload = JSONAPI::Serializable::Renderer.new.render(new_event, expose: { context: :webhook }).to_json

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
