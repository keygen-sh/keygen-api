# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed

  def perform(event_id)
    event      = Event.find(event_id)
    event_type = event.event_type
    whodunnit  = event.whodunnit
    resource   = event.resource

    if whodunnit.present?
      whodunnit.notify_of_event!(event: event_type.event, idempotency_key: event.idempotency_key) if
        whodunnit.class < Eventable &&
        whodunnit.listens_to?(event)

      # No use in attempting to resend the same idempotent event
      return if
        whodunnit == resource
    end

    resource.notify_of_event!(event: event_type.event, idempotency_key: event.idempotency_key) if
      resource.class < Eventable &&
      resource.listens_to?(event)
  end
end
