# frozen_string_literal: true

module RateLimiting
  extend ActiveSupport::Concern

  PUBLIC_RATE_LIMIT_KEYS = %w[
    req/ip/1s
    req/ip/1m
  ]

  def rate_limiting_data
    throttle_data = (request.env["rack.attack.throttle_data"] || {}).slice(*PUBLIC_RATE_LIMIT_KEYS)
    return unless
      throttle_data.present?

    key, data = throttle_data.max_by { |k, v| v[:count].to_f / v[:limit].to_f * 100 }
    return unless
      data.present?

    window = key.split('/').last
    period = data[:period].to_i
    count  = data[:count].to_i
    limit  = data[:limit].to_i
    now    = data[:epoch_time].to_i

    {
      window: window,
      count: count,
      limit: limit,
      remaining: [0, limit - count].max,
      reset: (now + (period - now % period)).to_i,
    }
  rescue => e
    Keygen.logger.exception e

    nil
  end
end
