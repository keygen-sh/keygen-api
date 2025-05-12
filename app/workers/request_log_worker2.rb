# frozen_string_literal: true

# FIXME(ezekg) rename after old worker queue drains
class RequestLogWorker2 < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*request_logs_attributes)
    RequestLog.insert_all(request_logs_attributes)
  end
end
