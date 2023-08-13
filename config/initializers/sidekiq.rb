# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-unique-jobs'
require 'sidekiq-cron'
require 'sidekiq/web'

SIDEKIQ_MAX_QUEUE_LATENCY =
  (ENV['SIDEKIQ_MAX_QUEUE_LATENCY'] || 30).to_i

# Configure Sidekiq's web interface to use basic authentication
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  compare = -> (a, b) { Rack::Utils.secure_compare(a, b) }
  hash    = -> (v)    { Digest::SHA256.hexdigest(v) }

  next false unless
    ENV['SIDEKIQ_WEB_USER'] && ENV['SIDEKIQ_WEB_PASSWORD']

  compare[hash[user], hash[ENV['SIDEKIQ_WEB_USER']]] &
    compare[hash[password], hash[ENV['SIDEKIQ_WEB_PASSWORD']]]
end

# Configure Sidekiq session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_interslice_session', path: '/-/sidekiq', same_site: :strict

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  config.logger = Rails.logger if Rails.env.test?
  config.redis  = {
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    size: 5,
    pool_timeout: 5,
    connect_timeout: 5,
    network_timeout: 5,
  }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
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

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
    unless ENV.key?('NO_CRONITOR')
      chain.add Sidekiq::Cronitor::ServerMiddleware
    end
  end

  SidekiqUniqueJobs::Server.configure(config)
end

# Configure Sidekiq unique jobs
SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test?
end

# Enable strict args for development/test
Sidekiq.strict_args! unless Rails.env.production?
