# frozen_string_literal: true

class EventLogWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :logs

  def perform(
    event,
    account_id,
    resource_type,
    resource_id,
    whodunnit_type,
    whodunnit_id,
    request_id,
    idempotency_key,
    metadata
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

  private

  def fetch_event_type_by_event(event)
    cache_key = EventType.cache_key(event)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event: event)
    end
  end
end
