# frozen_string_literal: true

# FIXME(ezekg) remove after migrating to new bulk worker and queue drains
class EventLogWorker < BaseWorker
  sidekiq_options queue: :logs

  def perform(
    event,
    account_id,
    resource_type,
    resource_id,
    whodunnit_type,
    whodunnit_id,
    request_log_id,
    idempotency_key,
    metadata,
    environment_id = nil
  )
    return unless
      Keygen.ee? && Keygen.ee { _1.entitled?(:event_logs) }

    metadata   = JSON.parse(metadata) if metadata.present?
    event_type = fetch_event_type_by_event(event)
    event_log  = EventLog.create!(
      id: UUID7.generate,
      event_type_id: event_type.id,
      idempotency_key:,
      account_id:,
      environment_id:,
      resource_type:,
      resource_id:,
      whodunnit_type:,
      whodunnit_id:,
      request_log_id:,
      metadata:,
    )
  end

  private

  def fetch_event_type_by_event(event)
    cache_key = EventType.cache_key(event)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by!(event: event)
    end
  end
end
