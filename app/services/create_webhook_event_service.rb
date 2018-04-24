class CreateWebhookEventService < BaseService

  def initialize(event:, account:, resource:, meta: nil)
    @event    = event
    @account  = account
    @resource = resource
    @meta     = meta
  end

  def execute
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

    # TODO: Move this out of the webhook event service
    begin
      RecordMetricService.new(
        metric: event,
        account: account,
        data: { resource: resource.id }.tap { |data|
          %w[product policy license user].map(&:to_sym).each do |r|
            data[r] = resource.send(r)&.id if resource.respond_to? r
          end
        }.compact
      ).execute
    rescue
      # noop
    end

    account&.webhook_endpoints.find_each do |endpoint|
      # Create a partial event (we'll complete it after the job is fired)
      webhook_event = account.webhook_events.create(
        endpoint: endpoint.url,
        event: event
      )

      # Serialize the event and decode so we can use in webhook job
      payload = JSONAPI::Serializable::Renderer.new.render(webhook_event, options)

      # Append meta to options for resource payload
      opts = options
      opts.merge! meta: @meta.transform_keys { |k| k.to_s.camelize :lower } unless @meta.nil?

      # Set the payload attr of the webhook payload (since it's incomplete at the moment)
      payload[:data][:attributes][:payload] = JSONAPI::Serializable::Renderer.new.render(resource, opts).to_json

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

  private

  attr_reader :event, :account, :resource, :meta
end
