# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed

  def perform(event_id)
    event      = Event.find(event_id)
    event_type = event.event_type
    resource   = event.resource
    created_by = event.created_by

    resource.notify!(event: event_type.event) unless
      resource.class < Eventable

    created_by.notify!(event: event_type.event) unless
      created_by.class < Eventable &&
      created_by != resource
  end
end
