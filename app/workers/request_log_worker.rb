# frozen_string_literal: true

# FIXME(ezekg) need to move this to a RequestLogWorker2 class to migrate
class RequestLogWorker < BaseWorker
  include PerformBulk::Job

  sidekiq_options queue: :logs

  def perform(*request_logs)
    RequestLog.insert_all(request_logs)
  end
end
