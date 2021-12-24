# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed

  def perform(event_id)
    event      = Event.find(event_id)
    event_type = event.event_type
    initiator  = event.initiator
    resource   = event.resource

    if initiator.present?
      initiator.notify_of_event!(event: event_type.event, idempotency_key: event.idempotency_key) if
        initiator.class < Eventable &&
        initiator.listens_to?(event)

      # No use in attempting to resend the same idempotent event
      return if
        initiator == resource
    end

    resource.notify_of_event!(event: event_type.event, idempotency_key: event.idempotency_key) if
      resource.class < Eventable &&
      initiator.listens_to?(event)
  end
end
