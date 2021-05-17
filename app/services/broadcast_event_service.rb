# frozen_string_literal: true

class BroadcastEventService < BaseService
  def initialize(event:, account:, resource:, meta: nil)
    @event    = event
    @account  = account
    @resource = resource
    @meta     = meta
  end

  def call
    options = {
      expose: { url_helpers: Rails.application.routes.url_helpers, context: :webhook },
      class: SERIALIZABLE_CLASSES,
    }

    begin
      RecordMetricService.call(
        metric: event,
        account: account,
        resource: resource
      )
    rescue
      # noop
    end

    # Append meta to options for resource payload and serialize
    # for the async event creation worker
    options.merge! meta: @meta.transform_keys { |k| k.to_s.camelize :lower } unless @meta.nil?
    payload = JSONAPI::Serializable::Renderer.new.render(resource, options).to_json

    CreateWebhookEventsWorker.perform_async(
      event,
      account.id,
      payload
    )
  end

  private

  attr_reader :event, :account, :resource, :meta
end
