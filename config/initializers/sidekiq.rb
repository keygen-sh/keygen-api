# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq-status'
require 'sidekiq-cron'
require 'sidekiq/throttled'
require 'sidekiq/web'

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

# Configure Sidekiq's web interface to use basic authentication
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  compare = -> (a, b) { Rack::Utils.secure_compare(a, b) }
  hash = -> (v) { Digest::SHA256.hexdigest(v) }
  env = -> (k) { ENV.fetch(k.to_s, '') }

  compare[hash[user], hash[env[:SIDEKIQ_WEB_USER]]] &
    compare[hash[password], hash[env[:SIDEKIQ_WEB_PASSWORD]]]
end

# Configure Sidekiq session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_interslice_session', path: '/-/sidekiq', same_site: :strict

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  config.redis = {
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    size: 5,
    pool_timeout: 5,
    connect_timeout: 5,
    network_timeout: 5,
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 3.days
  end
end

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  config.redis = {
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    size: 25,
    pool_timeout: 5,
    connect_timeout: 5,
    network_timeout: 5,
  }

  schedule_file = Rails.root.join 'config', 'schedule.yml'

  if File.exist?(schedule_file)
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
    chain.add Sidekiq::Status::ClientMiddleware, expiration: 3.days
  end

  config.server_middleware do |chain|
    chain.add Sidekiq::Status::ServerMiddleware, expiration: 3.days
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

# Configure Sidekiq unique jobs
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end

# Configure Sidekiq throttled
Sidekiq::Throttled.setup!
