class WebhookEventService < BaseService

  def initialize(event:, account:, resource:)
    @event    = event
    @account  = account
    @resource = resource
  end

  def execute
    account&.webhook_endpoints.find_each do |endpoint|
      payload = ActiveModelSerializers::SerializableResource.new(resource).serializable_hash.merge({
        event: event
      }).to_json

      jid = WebhookWorker.perform_async(
        account.id,
        endpoint.url,
        payload
      )

      account.webhook_events << account.webhook_events.new({
        endpoint: endpoint.url,
        payload: payload,
        jid: jid
      })
    end
  rescue
    false
  end

  private

  attr_reader :event, :account, :resource
end
