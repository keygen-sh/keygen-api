require 'sidekiq'
require 'sidekiq-status'
require 'sidekiq-cron'
require "sidekiq/throttled"

SIDEKIQ_MAX_QUEUE_LATENCY =
  (ENV['SIDEKIQ_MAX_QUEUE_LATENCY'] || 30).to_i

Sidekiq.configure_client do |config|
  config.redis = { size: 1 }

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 24.hours
  end
end

Sidekiq.configure_server do |config|
  schedule_file = Rails.root.join 'config', 'schedule.yml'

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 24.hours
  end

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 24.hours
  end
end

Sidekiq::Throttled.setup!
