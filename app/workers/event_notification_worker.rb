# frozen_string_literal: true

class EventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :events,
                  lock: :until_executed,
                  retry: 0,
                  dead: false

  def perform(event_id)
    event    = Event.find(event_id)
    resource = event.resource

    return unless
      resource.class.include?(Eventable)

    resource.notify!(
      event: event.event_type.event
    )
  end
end
