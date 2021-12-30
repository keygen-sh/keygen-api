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

    begin
      # FIXME(ezekg) Should we pass in the entire JSONAPI :document and require the caller
      #              to also specify :metadata for the broadcasted event? This would let
      #              us keep any event data separate from the webhook payload.
      metadata =
        case event
        when /^release\.upgraded$/
          { prev: meta[:current], next: meta[:next] }
        when /^license\.validation\./
          { code: meta[:constant ] }
        when /\.updated$/
          { diff: resource.to_diff } if
            resource.class < Diffable
        else
          nil
        end

      BroadcastEventWorker.perform_async(
        event_name: event,
        account_id: Current.account.id,
        resource_type: resource.class.name,
        resource_id: resource.id,
        whodunnit_type: Current.bearer&.class&.name,
        whodunnit_id: Current.bearer&.id,
        request_id: Current.request_id,
        idempotency_key: SecureRandom.hex,
        metadata: metadata,
      )
    rescue => e
      Keygen.logger.exception(e)
    end

    # Append meta to options for resource payload and serialize
    # for the async event creation worker
    begin
      options = {}
      options.merge!(meta: meta.transform_keys { |k| k.to_s.camelize(:lower) }) unless
        meta.nil?

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
