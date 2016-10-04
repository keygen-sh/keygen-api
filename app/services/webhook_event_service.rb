class WebhookEventService

  def initialize(event, params)
    @event = event
    @account = params[:account]
    @resource = params[:resource]
  end

  def fire
    account&.webhooks.each do |webhook|
      WebhookWorker.perform_async(
        webhook.endpoint,
        ActiveModelSerializers::SerializableResource.new(resource).serializable_hash.merge({
          event: event
        }).to_json
      )
    end
  rescue
    false
  end

  private

  attr_reader :event, :account, :resource
end
