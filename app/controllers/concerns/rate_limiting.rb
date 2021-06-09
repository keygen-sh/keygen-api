module RateLimiting
  extend ActiveSupport::Concern

  PUBLIC_RATE_LIMIT_KEYS = %w[
    req/ip/burst/30s
    req/ip/burst/2m
    req/ip/burst/5m
    req/ip/burst/10m
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
    count = data[:count].to_i
    limit = data[:limit].to_i
    now = Time.current

    {
      window: window,
      count: count,
      limit: limit,
      remaining: [0, limit - count].max,
      reset: (now + (period - now.to_i % period)).to_i,
    }
  rescue => e
    Keygen.logger.exception e

    nil
  end
end
