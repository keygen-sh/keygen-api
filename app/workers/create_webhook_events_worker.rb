# frozen_string_literal: true

class CreateWebhookEventsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :webhooks, lock: :until_executed

  def perform(event, account_id, data)
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find account_id
    end

    account.webhook_endpoints.find_each do |endpoint|
      next unless endpoint.subscribed? event

      event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
        EventType.find_or_create_by! event: event
      end

      # Create a partial event (we'll complete it after the job is fired)
      webhook_event = account.webhook_events.create!(
        endpoint: endpoint.url,
        event_type: event_type,
        status: 'DELIVERING',
      )

      # Serialize the event and decode so we can use in webhook job
      payload = Keygen::JSONAPI::Renderer.new(context: :webhook).render(webhook_event)

      # Set the payload attr of the webhook (since it's incomplete at the moment)
      payload[:data][:attributes][:payload] = data

      # Enqueue the worker, which will fire off the webhook
      jid = WebhookWorker.perform_async(
        account.id,
        webhook_event.id,
        endpoint.id,
        payload.to_json
      )

      # Update the event to contain the payload and job identifier
      webhook_event.update!(
        payload: payload.dig(:data, :attributes, :payload),
        jid: jid
      )
    end
  end
end
