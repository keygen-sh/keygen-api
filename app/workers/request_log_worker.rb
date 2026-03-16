# frozen_string_literal: true

class RequestLogWorker < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*request_logs_attributes)
    RequestLog.insert_all(request_logs_attributes)
  end
end

# FIXME(ezekg) remove after old worker queue drains
RequestLogWorker2 = RequestLogWorker
