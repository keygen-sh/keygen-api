# frozen_string_literal: true

# FIXME(ezekg) need to move this to a RequestLogWorker2 class to migrate
class RequestLogWorker < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*request_logs_attributes)
    RequestLog.insert_all(request_logs_attributes)
  end
end
