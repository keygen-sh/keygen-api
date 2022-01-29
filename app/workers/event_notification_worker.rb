# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed,
                  queue: :logs

  def perform(event_log_id)
    event_log  = EventLog.find(event_log_id)
    event_type = event_log.event_type
    whodunnit  = event_log.whodunnit
    resource   = event_log.resource

    if whodunnit.present?
      whodunnit.notify_of_event!(event_type.event, idempotency_key: "#{whodunnit.id}:#{event_log.idempotency_key}") if
        whodunnit.respond_to?(:notify_of_event!)

      # No use in attempting to resend the same idempotent event
      return if
        whodunnit == resource
    end

    resource.notify_of_event!(event_type.event, idempotency_key: "#{resource.id}:#{event_log.idempotency_key}") if
      resource.respond_to?(:notify_of_event!)
  end
end
