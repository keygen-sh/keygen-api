# frozen_string_literal: true

unless ENV.key?('NO_SENTRY')
  Sentry.init do |config|
    config.dsn                  = ENV.fetch('SENTRY_DSN')                  { nil }
    config.traces_sample_rate   = ENV.fetch('SENTRY_TRACES_SAMPLE_RATE')   { 0.0 }.to_f
    config.profiles_sample_rate = ENV.fetch('SENTRY_PROFILES_SAMPLE_RATE') { 0.0 }.to_f
    config.excluded_exceptions += ENV.fetch('SENTRY_EXCLUDED_EXCEPTIONS')  { ''  }.split(',')
    config.environment          = Rails.env
    config.sdk_logger           = Sentry::Logger.new(STDOUT)
    config.sdk_logger.level     = Logger::WARN
  end
end
