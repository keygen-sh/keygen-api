# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq-cron'
require 'sidekiq/web'

SIDEKIQ_MAX_QUEUE_LATENCY =
  (ENV['SIDEKIQ_MAX_QUEUE_LATENCY'] || 30).to_i

# Configure Sidekiq's web interface to use basic authentication
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  compare = -> (a, b) { Rack::Utils.secure_compare(a, b) }
  hash    = -> (v)    { Digest::SHA256.hexdigest(v) }

  u = ENV['SIDEKIQ_WEB_USER']
  p = ENV['SIDEKIQ_WEB_PASSWORD']
  next false unless
    u.present? && p.present?

  compare[hash[user], hash[u]] & compare[hash[password], hash[p]]
end

# Configure Sidekiq session middleware
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_interslice_session', path: '/-/sidekiq', same_site: :strict

# Configure Sidekiq client
Sidekiq.configure_client do |config|
  config.logger       = Rails.logger if Rails.env.test?
  config.logger.level = Rails.logger.level
  config.redis  = {
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    size: ENV.fetch('REDIS_POOL_SIZE') { ENV.fetch('RAILS_MAX_THREADS', 2) }.to_i,
    pool_timeout: ENV.fetch('REDIS_POOL_TIMEOUT') { 5 }.to_i,
    connect_timeout: ENV.fetch('REDIS_CONNECT_TIMEOUT') { 5 }.to_i,
    network_timeout: ENV.fetch('REDIS_NETWORK_TIMEOUT') { 5 }.to_i,
    write_timeout: ENV.fetch('REDIS_WRITE_TIMEOUT') { 5 }.to_i,
    read_timeout: ENV.fetch('REDIS_READ_TIMEOUT') { 5 }.to_i,
  }
end

# Configure Sidekiq server
Sidekiq.configure_server do |config|
  PerformBulk.bulk_fetch!(config,
    concurrency: ENV.fetch('PERFORM_BULK_CONCURRENCY', 1).to_i,
    batch_size: ENV.fetch('PERFORM_BULK_BATCH_SIZE', 100).to_i,
  )

  config.logger.level = Rails.logger.level
  config.redis = {
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    size: ENV.fetch('REDIS_POOL_SIZE') { ENV.fetch('SIDEKIQ_CONCURRENCY', 10) }.to_i,
    pool_timeout: ENV.fetch('REDIS_POOL_TIMEOUT') { 5 }.to_i,
    connect_timeout: ENV.fetch('REDIS_CONNECT_TIMEOUT') { 5 }.to_i,
    network_timeout: ENV.fetch('REDIS_NETWORK_TIMEOUT') { 5 }.to_i,
    write_timeout: ENV.fetch('REDIS_WRITE_TIMEOUT') { 5 }.to_i,
    read_timeout: ENV.fetch('REDIS_READ_TIMEOUT') { 5 }.to_i,
  }

  config.server_middleware do |chain|
    unless ENV.key?('NO_CRONITOR')
      chain.add Sidekiq::Cronitor::ServerMiddleware
    end
  end
end

# Enable strict args for development/test
Sidekiq.strict_args! unless Rails.env.production?
