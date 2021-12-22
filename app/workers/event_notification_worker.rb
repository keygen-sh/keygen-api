# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed

  def perform(event_id)
    event      = Event.find(event_id)
    event_type = event.event_type
    created_by = event.created_by
    resource   = event.resource

    created_by.notify!(event: event_type.event, idempotency_key: event.idempotency_key) unless
      created_by.class < Eventable

    resource.notify!(event: event_type.event, idempotency_key: event.idempotency_key) unless
      resource.class < Eventable
  end
end
