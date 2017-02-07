class CreateWebhookEventService < BaseService

  def initialize(event:, account:, resource:)
    @event    = event
    @account  = account
    @resource = resource
  end

  def execute
    options = {
      expose: { url_helpers: Rails.application.routes.url_helpers }
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
      payload = ActiveSupport::JSON.decode(
        JSONAPI::Serializable::Renderer.render(webhook_event, options)
      )

      # Set the payload attr of the webhook payload (since it's incomplete at the moment)
      payload["data"]["attributes"]["payload"] = ActiveSupport::JSON.decode(
        JSONAPI::Serializable::Renderer.render(resource, options)
      )

      # Enqueue the worker, which will fire off the webhook
      jid = WebhookWorker.perform_async(
        endpoint.url,
        payload.to_json
      )

      # Update the event to contain the payload and job identifier
      webhook_event.update(
        payload: payload.dig("data", "attributes", "payload").to_json,
        jid: jid
      )
    end
  rescue Redis::CannotConnectError
    false
  end

  private

  attr_reader :event, :account, :resource
end
