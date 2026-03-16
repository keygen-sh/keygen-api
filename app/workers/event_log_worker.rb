# frozen_string_literal: true

class EventLogWorker < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*event_logs_attributes)
    EventLog.insert_all(event_logs_attributes)
  end
end

# FIXME(ezekg) remove after old worker queue drains
EventLogWorker2 = EventLogWorker
