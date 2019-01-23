require 'bullet'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.
  config.cache_store = :memory_store, { namespace: "test_#{ENV['TEST_ENV_NUMBER']}" }

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => 'public, max-age=3600'
  }

  # Show full error reports and disable caching.
  config.action_controller.perform_caching = false

  # Show full error reports.
  config.consider_all_requests_local = false

  # Route exceptions to error controller.
  config.exceptions_app = self.routes

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
