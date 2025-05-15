# frozen_string_literal: true

# FIXME(ezekg) rename after old webhook worker queue is drained
class CreateWebhookEventsWorker2 < BaseWorker
  sidekiq_options queue: :webhooks

  def perform(
    event,
    webhook_endpoint_ids,
    resource_payload,
    account_id,
    environment_id
  )
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find(account_id)
    end

    event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event:)
    end

    webhook_endpoints = account.webhook_endpoints.where(id: webhook_endpoint_ids).for_environment(
      environment_id,
      strict: true,
    )

    webhook_endpoints.find_each do |webhook_endpoint|
      next unless
        webhook_endpoint.subscribed?(event)

      # create a partial event (we'll complete it after the job is fired)
      webhook_event = account.webhook_events.create!(
        api_version: webhook_endpoint.api_version,
        endpoint: webhook_endpoint.url, # FIXME(ezekg) remove this in favor of association?
        event_type: event_type,
        status: 'DELIVERING',
        webhook_endpoint:,
        environment_id:,
      )

      # serialize the event and decode so we can use in webhook job
      webhook = Keygen::JSONAPI::Renderer.new(account:, api_version: webhook_endpoint.api_version, context: :webhook)
                                         .render(webhook_event)

      # migrate the resource payload (right now it's for the current API version and it needs
      # to be migrated to the endpoint's API version)
      data     = resource_payload.deep_symbolize_keys
      migrator = RequestMigrations::Migrator.new(
        from: CURRENT_API_VERSION,
        to: webhook_endpoint.api_version ||
            account.api_version,
      )

      migrator.migrate!(
        data:,
      )

      # set the webhook's payload (since it's incomplete at the moment)
      webhook[:data][:attributes][:payload] = data.to_json

      # enqueue the worker and fire off the webhook
      jid = WebhookWorker.perform_async(
        account.id,
        webhook_event.id,
        webhook_endpoint.id,
        webhook.to_json,
      )

      # update the event to contain the payload and job identifier
      webhook_event.update!(
        payload: data.to_json,
        jid:,
      )
    end
  end
end
