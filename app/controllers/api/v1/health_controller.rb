# frozen_string_literal: true

require 'sidekiq/api'

module Api::V1
  class HealthController < Api::V1::BaseController
    skip_verify_authorized

    def general_health
      render status: 204
    end

    def webhook_health
      process_ok = Sidekiq::ProcessSet.new.size > 0
      latency_ok = Sidekiq::Queue.new.latency < SIDEKIQ_MAX_QUEUE_LATENCY
      status = process_ok && latency_ok ? 204 : 500

      render status: status
    end

    def general_ping
      render status: 200
    end
  end
end
