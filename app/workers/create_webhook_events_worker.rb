class CreateWebhookEventsWorker
  include Sidekiq::Worker

  sidekiq_options queue: :webhooks

  def perform(event, account_id, data)
    account = Account.find account_id
    options = {
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
    }

    account.webhook_endpoints.find_each do |endpoint|
      next unless endpoint.subscribed? event

      # Create a partial event (we'll complete it after the job is fired)
      webhook_event = account.webhook_events.create(
        endpoint: endpoint.url,
        event: event
      )

      # Serialize the event and decode so we can use in webhook job
      payload = JSONAPI::Serializable::Renderer.new.render(webhook_event, options)

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
      webhook_event.update(
        payload: payload.dig(:data, :attributes, :payload),
        jid: jid
      )
    end
  end
end