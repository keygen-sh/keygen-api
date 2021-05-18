# frozen_string_literal: true

class BroadcastEventService < BaseService
  def initialize(event:, account:, resource:, meta: nil)
    @event    = event
    @account  = account
    @resource = resource
    @meta     = meta
  end

  def call
    begin
      RecordMetricService.call(metric: event, account: account, resource: resource)
    rescue => e
      Keygen.logger.exception(e)
    end

    # Append meta to options for resource payload and serialize
    # for the async event creation worker
    begin
      options = {}
      options.merge! meta: meta.transform_keys { |k| k.to_s.camelize(:lower) } unless meta.nil?

      payload = Keygen::JSONAPI::Renderer.new(context: :webhook)
                                         .render(resource, options)
                                         .to_json

      CreateWebhookEventsWorker.perform_async(
        event,
        account.id,
        payload
      )
    rescue => e
      Keygen.logger.exception(e)

      raise e
    end
  end

  private

  attr_reader :event, :account, :resource, :meta
end
