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
    request_log_id,
    idempotency_key,
    metadata
  )
    return unless
      Keygen.ee? && Keygen.ee.entitled?('EVENT_LOGS')

    metadata   = JSON.parse(metadata) if metadata.present?
    event_type = fetch_event_type_by_event(event)
    event_log  = EventLog.create!(
      event_type_id: event_type.id,
      idempotency_key:,
      account_id:,
      resource_type:,
      resource_id:,
      whodunnit_type:,
      whodunnit_id:,
      request_log_id:,
      metadata:,
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
