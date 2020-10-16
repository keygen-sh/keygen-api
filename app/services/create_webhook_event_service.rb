# frozen_string_literal: true

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
        License: SerializableLicense,
        Machine: SerializableMachine,
        Key: SerializableKey,
        Billing: SerializableBilling,
        Plan: SerializablePlan,
        WebhookEndpoint: SerializableWebhookEndpoint,
        WebhookEvent: SerializableWebhookEvent,
        Metric: SerializableMetric,
        SecondFactor: SerializableSecondFactor,
        Error: SerializableError
      }
    }

    # TODO: Move this out of the webhook event service
    begin
      RecordMetricService.new(
        metric: event,
        account: account,
        resource: resource
      ).execute
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
