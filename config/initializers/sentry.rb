# frozen_string_literal: true

unless ENV.key?('NO_SENTRY')
  Sentry.init do |config|
    config.dsn                = ENV.fetch('SENTRY_DSN')         { nil }
    config.traces_sample_rate = ENV.fetch('SENTRY_SAMPLE_RATE') { 0.0 }.to_f
    config.environment        = Rails.env
  end
end
