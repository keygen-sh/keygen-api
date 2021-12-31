# frozen_string_literal: true

class BroadcastEventWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :logs

  def perform(kwargs)
    perform_with_kwargs(**kwargs.to_h.symbolize_keys)
  end

  private

  def perform_with_kwargs(
    event:,
    account_id:,
    resource_type:,
    resource_id:,
    whodunnit_type:,
    whodunnit_id:,
    request_id: nil,
    idempotency_key: nil,
    metadata: nil
  )
    event_type = fetch_event_type_by_event(event)
    event_log  = EventLog.create!(
      idempotency_key: idempotency_key,
      event_type_id: event_type.id,
      account_id: account_id,
      resource_type: resource_type,
      resource_id: resource_id,
      whodunnit_type: whodunnit_type,
      whodunnit_id: whodunnit_id,
      request_log_id: request_id,
      metadata: metadata,
    )

    EventNotificationWorker.perform_async(event_log.id)
  end

  def fetch_event_type_by_event(event)
    cache_key = EventType.cache_key(event)

    cache.fetch(cache_key, skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event: event)
    end
  end

  def cache
    Rails.cache
  end
end
