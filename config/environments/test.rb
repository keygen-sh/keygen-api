# frozen_string_literal: true

require 'bullet'

Rails.application.configure do
  # Configure 'rails notes' to inspect Cucumber files
  config.annotations.register_directories('features')
  config.annotations.register_extensions('feature') { |tag| /#\s*(#{tag}):?\s*(.*)$/ }

  # Settings specified here will take precedence over those in config/application.rb.

  config.active_record.default_timezone = :utc
  config.time_zone = 'UTC'

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = ENV.key?('CI')

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Disable logging in test environment unless explicitly enabled.
  unless ENV.key?('RAILS_LOG')
    config.logger    = Logger.new(nil)
    config.log_level = :fatal
  end

  # Enable/disable caching with redis.
  if ENV['REDIS_URL'].present?
    config.action_controller.perform_caching = true
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_URL'],
      db: ENV['TEST_ENV_NUMBER'].to_i,
      pool: {
        size: ENV.fetch('REDIS_POOL_SIZE') { ENV.fetch('RAILS_MAX_THREADS', 2) }.to_i,
        timeout: ENV.fetch('REDIS_POOL_TIMEOUT') { 5 }.to_i,
      },
      connect_timeout: ENV.fetch('REDIS_CONNECT_TIMEOUT') { 5 }.to_i,
      read_timeout: ENV.fetch('REDIS_READ_TIMEOUT') { 5 }.to_i,
      write_timeout: ENV.fetch('REDIS_WRITE_TIMEOUT') { 5 }.to_i,
      reconnect_attempts: ENV.fetch('REDIS_RECONNECT_ATTEMPTS') { 5 }.to_i,
      reconnect_delay: ENV.fetch('REDIS_RECONNECT_DELAY') { 1 }.to_f,
      reconnect_delay_max: ENV.fetch('REDIS_RECONNECT_DELAY_MAX') { 1 }.to_f,
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :memory_store
  end

  # Show full error reports and disable caching.
  config.action_controller.perform_caching = false

  # Show full error reports.
  config.consider_all_requests_local = false

  # Route exceptions to error controller.
  config.exceptions_app = self.routes

  # Enable query logs.
  config.active_record.query_log_tags = %i[application pid controller action job]
  config.active_record.query_log_tags_enabled = true
  config.active_record.verbose_query_logs = true

  # Raise errors on unpermitted params.
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false
  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Disable colored logs in test env
  config.colorize_logging = false

  # Configure Bullet for performance tests
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true

    # Raise an error if e.g. an n+1 query is detected
    Bullet.raise = true

    # FIXME(ezekg) For some reason, we're seeing failures even though
    #              we're not eager loading anything.
    Bullet.unused_eager_loading_enable = false
  end
end

# Speed up tests by disabling the WAL.
ActiveSupport.on_load :active_record_postgresqladapter do
  self.create_unlogged_tables = true
end
