# frozen_string_literal: true

# FIXME(ezekg) remove after migrating to new webhook worker and queue is drained
class CreateWebhookEventsWorker < BaseWorker
  sidekiq_options queue: :webhooks

  def perform(event, account_id, payload, environment_id = nil)
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find(account_id)
    end

    event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event:)
    end

    webhook_endpoints = account.webhook_endpoints.for_environment(
      environment_id,
      strict: true,
    )

    webhook_endpoints.unordered.find_each do |webhook_endpoint|
      next unless
        webhook_endpoint.subscribed?(event)

      # Create a partial event (we'll complete it after the job is fired)
      webhook_event = account.webhook_events.create!(
        api_version: webhook_endpoint.api_version,
        endpoint: webhook_endpoint.url,
        event_type: event_type,
        status: 'DELIVERING',
        environment_id:,
      )

      # Serialize the event and decode so we can use in webhook job
      webhook = Keygen::JSONAPI::Renderer.new(account:, api_version: webhook_endpoint.api_version, context: :webhook)
                                         .render(webhook_event)

      # Migrate the resource payload (right now it's for the current API version and it needs
      # to be migrated to the endpoint's API version)
      data     = JSON.parse(payload, symbolize_names: true)
      migrator = RequestMigrations::Migrator.new(
        from: CURRENT_API_VERSION,
        to: webhook_endpoint.api_version ||
            account.api_version,
      )

      migrator.migrate!(
        data:,
      )

      # Set the webhook's payload (since it's incomplete at the moment)
      webhook[:data][:attributes][:payload] = data.to_json

      # Enqueue the worker, which will fire off the webhook
      jid = WebhookWorker.perform_async(
        account.id,
        webhook_event.id,
        webhook_endpoint.id,
        webhook.to_json,
      )

      # Update the event to contain the payload and job identifier
      webhook_event.update!(
        payload: data.to_json,
        jid:,
      )
    end
  end
end
