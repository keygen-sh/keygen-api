# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq-status'
require 'sidekiq-cron'
require "sidekiq/throttled"

SIDEKIQ_MAX_QUEUE_LATENCY =
  (ENV['SIDEKIQ_MAX_QUEUE_LATENCY'] || 30).to_i

class Sidekiq::Status::ClientMiddleware
  # NOTE(ezekg) sidekiq-status needlessly stores the job args for display purposes in their UI,
  #             which we don't even use, and our args can be very large JSON payloads which
  #             causes unneeded bloat. At the time of this monkey patch, we had a 800MB keyspace
  #             for `sidekiq:status:*` for absolutely no benefit, since we don't use the UI.
  def display_args(msg, queue)
    nil
  end
end

Sidekiq.configure_client do |config|
  config.redis = { size: 5, pool_timeout: 5, connect_timeout: 5, network_timeout: 5 }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
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
    chain.add SidekiqUniqueJobs::Middleware::Server
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 3.days
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 3.days
  end

  SidekiqUniqueJobs::Server.configure(config)
end

SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end

Sidekiq::Throttled.setup!
