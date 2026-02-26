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

      event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
        EventType.find_or_create_by!(event:)
      end

      # NB(ezekg) use the current environment when available, otherwise fallback
      #           to the resource's environment
      environment = Current.environment || (resource.environment if resource.respond_to?(:environment))

      begin
        idempotency_key = SecureRandom.hex
        account_id      = Current.account_id || account.id
        environment_id  = Current.environment_id || environment&.id
        resource_type   = Current.resource_type || resource.class.name
        resource_id     = Current.resource_id || resource.id
        event_type_id   = event_type.id

        # NB(ezekg) these current attributes could be nil if e.g. the event is being
        #           generated via a background job like MachineHeartbeatWorker
        bearer_type     = Current.bearer_type
        bearer_id       = Current.bearer_id
        request_id      = Current.request_id

        Keygen.ee do |license|
          next unless
            license.entitled?(:event_logs)

          # FIXME(ezekg) Should we pass in the entire JSONAPI :document and require the caller
          #              to also specify :metadata for the broadcasted event? This would let
          #              us keep any event data separate from the webhook payload.
          metadata =
            case event
            when /^release\.upgraded$/
              { product: resource.product_id, package: resource.package_id, prev: meta[:current], next: meta[:next] }
            when /^artifact\.downloaded$/,
                 /^release\.downloaded$/
              { product: resource.product_id, package: resource.package_id, version: resource.version }
            when /^license\.validation\./
              { code: meta[:code] }
            when /\.updated$/
              { diff: resource.to_diff } if resource.class < Diffable
            when /\.entitlements\.(de|at)tached$/
              { codes: account.entitlements.where(id: resource.map(&:entitlement_id)).pluck(:code) }
            else
              nil
            end

          EventLogWorker2.perform_async(
            'id' => SecureRandom.uuid_v7,
            'event_type_id' => event_type_id,
            'account_id' => account_id,
            'environment_id' => environment_id,
            'idempotency_key' => idempotency_key,
            'created_date' => Date.today.iso8601,
            'created_at' => Time.current.iso8601(6),
            'resource_type' => resource_type,
            'resource_id' => resource_id,
            'whodunnit_type' => bearer_type,
            'whodunnit_id' => bearer_id,
            'request_log_id' => request_id,
            'metadata' => metadata.as_json,
            # NB(ezekg) this is only applicable to clickhouse (gets ignored by primary)
            'ttl' => account.event_log_retention_duration&.to_i,
          )
        end

        EventNotificationWorker.perform_async(
          event,
          account_id,
          resource_type,
          resource_id,
          bearer_type,
          bearer_id,
          idempotency_key,
        )
      rescue => e
        Keygen.logger.exception(e)
      end

      # broadcast the event to all relevant endpoints
      BroadcastWebhookService.call(
        event:,
        account:,
        environment:,
        resource:,
        meta:,
      )
    end
  end

  private

  attr_reader :events,
              :account,
              :resource,
              :meta
end
