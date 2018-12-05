require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq-status'
require 'sidekiq-cron'
require "sidekiq/throttled"

SIDEKIQ_MAX_QUEUE_LATENCY =
  (ENV['SIDEKIQ_MAX_QUEUE_LATENCY'] || 30).to_i

Sidekiq.configure_client do |config|
  config.redis = { size: 5, pool_timeout: 5, connect_timeout: 5, network_timeout: 5 }

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 3.days
  end
end

Sidekiq.configure_server do |config|
  config.redis = { size: 25, pool_timeout: 5, connect_timeout: 5, network_timeout: 5 }

  schedule_file = Rails.root.join 'config', 'schedule.yml'

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 3.days
  end

  config.client_middleware do |chain|
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 3.days
  end
end

SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end

Sidekiq::Throttled.setup!
