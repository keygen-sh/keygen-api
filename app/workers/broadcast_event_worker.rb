# frozen_string_literal: true

class BroadcastEventWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :events

  def perform(kwargs)
    perform_with_kwargs(**kwargs.to_h.symbolize_keys)
  end

  private

  def perform_with_kwargs(
    event_name:,
    account_id:,
    resource_type:,
    resource_id:,
    initiator_type:,
    initiator_id:,
    request_id: nil,
    idempotency_key: nil,
    metadata: nil
  )
    event_type = fetch_event_type_by_event(event_name)
    event      = Event.create!(
      idempotency_key: idempotency_key,
      event_type_id: event_type.id,
      account_id: account_id,
      resource_type: resource_type,
      resource_id: resource_id,
      initiator_type: initiator_type,
      initiator_id: initiator_id,
      request_log_id: request_id,
      metadata: metadata,
    )

    EventNotificationWorker.perform_async(event.id)
  end

  def fetch_event_type_by_event(event_name)
    cache_key = EventType.cache_key(event_name)

    cache.fetch(cache_key, skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event: event_name)
    end
  end

  def cache
    Rails.cache
  end
end
