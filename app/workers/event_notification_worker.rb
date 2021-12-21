# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed

  def perform(event_id)
    event      = Event.find(event_id)
    event_type = event.event_type
    requestor  = event.request_log.requestor
    resource   = event.resource

    requestor.notify!(event: event_type.event) unless
      requestor.class < Eventable

    return if
      resource == requestor

    resource.notify!(event: event_type.event) unless
      resource.class < Eventable
  end
end
