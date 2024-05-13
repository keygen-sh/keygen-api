# frozen_string_literal: true

class RetryWebhookEventService < BaseService
  def initialize(event:)
    @event = event
  end

  def call
    account = event.account

    # FIXME(ezekg) Add an association so we don't have to do this stupid lookup
    endpoint = account.webhook_endpoints.find_by(url: event.endpoint)
    return if
      endpoint.nil?

    new_event = account.webhook_events.create(
      idempotency_token: event.idempotency_token,
      api_version: event.api_version,
      endpoint: event.endpoint,
      payload: event.payload,
      environment_id: event.environment_id,
      event_type: event.event_type,
      status: 'DELIVERING',
    )

    payload = Keygen::JSONAPI::Renderer.new(account:, api_version: new_event.api_version, context: :webhook)
                                       .render(new_event)
                                       .to_json

    jid = WebhookWorker.perform_async(
      account.id,
      new_event.id,
      endpoint.id,
      payload,
    )

    new_event.update(jid:)

    new_event
  end

  private

  attr_reader :event
end
