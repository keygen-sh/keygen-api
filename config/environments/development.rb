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
    config.cache_store = :redis_store, ENV['REDIS_URL']
  else
    config.action_controller.perform_caching = false
    config.cache_store = :memory_store
  end

  # Update default logger.
  logger = ActiveSupport::Logger.new(STDOUT)
  logger.formatter = config.log_formatter

  config.logger = ActiveSupport::TaggedLogging.new(logger)

  # Using Rspec for tests.
  config.action_mailer.preview_path = 'spec/mailers/previews'

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
