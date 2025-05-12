# frozen_string_literal: true

# FIXME(ezekg) rename after old worker queue drains
class EventLogWorker2 < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*event_logs_attributes)
    EventLog.insert_all(event_logs_attributes)
  end
end
