# frozen_string_literal: true

# FIXME(ezekg) need to move this to an EventLogWorker2 class to migrate
class EventLogWorker < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*event_logs_attributes)
    EventLog.insert_all(event_logs_attributes)
  end
end
