# frozen_string_literal: true

require 'sidekiq/api'

module Api::V1
  class HealthController < Api::V1::BaseController
    # some platforms like GCP are very specific with health check status codes,
    # so they may require a 200 even though 204 is more appropriate.
    HTTP_HEALTH_CHECK_STATUS_CODE = ENV.fetch('HTTP_HEALTH_CHECK_STATUS_CODE', 204).to_i

    skip_verify_authorized

    def general_health
      render status: HTTP_HEALTH_CHECK_STATUS_CODE
    end

    def webhook_health
      process_ok = Sidekiq::ProcessSet.new.size > 0
      latency_ok = Sidekiq::Queue.new.latency < SIDEKIQ_MAX_QUEUE_LATENCY
      status = process_ok && latency_ok ? HTTP_HEALTH_CHECK_STATUS_CODE : 500

      render status: status
    end

    def general_ping
      render status: 200
    end
  end
end
