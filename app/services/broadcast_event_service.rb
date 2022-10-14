# frozen_string_literal: true

class BroadcastEventService < BaseService
  def initialize(event:, account:, resource:, meta: nil)
    @events    = Array(event)
    @account   = account
    @resource  = resource
    @meta      = meta
  end

  def call
    events.each do |event|
      begin
        RecordMetricService.call(metric: event, account: account, resource: resource)
      rescue => e
        Keygen.logger.exception(e)
      end

      begin
        Keygen.ee do |license|
          next unless
            license.entitled?('EVENT_LOGS')

          # FIXME(ezekg) Should we pass in the entire JSONAPI :document and require the caller
          #              to also specify :metadata for the broadcasted event? This would let
          #              us keep any event data separate from the webhook payload.
          metadata =
            case event
            when /^release\.upgraded$/
              { prev: meta[:current], next: meta[:next] }
            when /^artifact\.downloaded$/,
                /^release\.downloaded$/
              { version: resource.version }
            when /^license\.validation\./
              { code: meta[:code] }
            when /\.updated$/
              { diff: resource.to_diff } if resource.class < Diffable
            when /\.entitlements\.(de|at)tached$/
              { codes: account.entitlements.where(id: resource.map(&:entitlement_id)).pluck(:code) }
            else
              nil
            end

          # NOTE(ezekg) These current attributes could be nil if e.g. the event is being
          #             generated via a background job like MachineHeartbeatWorker.
          EventLogWorker.perform_async(
            event,
            Current.account&.id || account.id,
            Current.resource&.class&.name || resource.class.name,
            Current.resource&.id || resource.id,
            Current.bearer&.class&.name,
            Current.bearer&.id,
            Current.request_id,
            SecureRandom.hex,
            metadata.to_json,
          )
        end
      rescue => e
        Keygen.logger.exception(e)
      end

      # Append meta to options for resource payload and serialize
      # for the async event creation worker
      begin
        options = {}
        options.merge!(meta: meta.transform_keys { |k| k.to_s.camelize(:lower) }) unless
          meta.nil?

        payload = Keygen::JSONAPI::Renderer.new(account:, context: :webhook)
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
  end

  private

  attr_reader :events,
              :account,
              :resource,
              :meta
end
