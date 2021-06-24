# frozen_string_literal: true

require 'bullet'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = false

  # Route exceptions to error controller.
  config.exceptions_app = self.routes

  # Raise errors on unpermitted params.
  config.action_controller.action_on_unpermitted_parameters = :raise

  # Enable/disable caching with redis.
  if ENV['REDIS_URL'].present?
    config.action_controller.perform_caching = true
    config.cache_store = :redis_cache_store, {
      url: ENV['REDIS_URL'],
      pool_size: ENV.fetch('REDIS_POOL_SIZE') { 5 }.to_i,
      pool_timeout: ENV.fetch('REDIS_POOL_TIMEOUT') { 5 }.to_i,
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

  # Update default logger.
  logger = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter

  config.logger = ActiveSupport::TaggedLogging.new(logger)

  # Using Rspec for tests.
  config.action_mailer.preview_path = "#{Rails.root}/spec/mailers/previews"

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Configure Bullet for performance tests
  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end
end
