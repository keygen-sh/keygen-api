# frozen_string_literal: true

Rails.application.configure do
  config.host_authorization = { exclude: -> req { req.path =~ %r(^/v\d+/health) } }
  config.hosts.concat(
    [ENV.fetch('KEYGEN_HOST'), *ENV.fetch('KEYGEN_HOSTS', '').split(',')].then { |host|
      host.uniq.compact_blank.map { _1.downcase.strip }
    },
  )

  # Disables security vulnerability
  config.assets.compile = false

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.cache_store = :redis_cache_store, {
    url: ENV['REDIS_URL'],
    pool: {
      size: ENV.fetch('REDIS_POOL_SIZE') { 5 }.to_i,
      timeout: ENV.fetch('REDIS_POOL_TIMEOUT') { 5 }.to_i,
    },
    connect_timeout: ENV.fetch('REDIS_CONNECT_TIMEOUT') { 5 }.to_i,
    read_timeout: ENV.fetch('REDIS_READ_TIMEOUT') { 5 }.to_i,
    write_timeout: ENV.fetch('REDIS_WRITE_TIMEOUT') { 5 }.to_i,
    reconnect_attempts: ENV.fetch('REDIS_RECONNECT_ATTEMPTS') { 5 }.to_i,
    reconnect_delay: ENV.fetch('REDIS_RECONNECT_DELAY') { 1 }.to_f,
    reconnect_delay_max: ENV.fetch('REDIS_RECONNECT_DELAY_MAX') { 1 }.to_f,
    ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
    error_handler: -> (method:, returning:, exception:) {
      Keygen.logger.exception exception
    },
  }

  # Route exceptions to error controller.
  config.exceptions_app = self.routes

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Action Cable endpoint configuration
  # config.action_cable.url = 'wss://example.com/cable'
  # config.action_cable.allowed_request_origins = [ 'http://example.com', /http:\/\/example.*/ ]

  # Don't mount Action Cable in the main server process.
  # config.action_cable.mount_path = nil

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true
  config.ssl_options = {
    redirect: { exclude: -> req { req.path =~ %r(^/v\d+/health) } },
  }

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = ENV.fetch('RAILS_LOG_LEVEL') { :info }.to_sym

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use a real queuing backend for Active Job (and separate queues per environment)
  # config.active_job.queue_adapter     = :resque
  # config.active_job.queue_name_prefix = "api_#{Rails.env}"
  config.action_mailer.perform_caching = false

  # SendGrid settings
  unless ENV.key?('NO_SENDGRID')
    config.action_mailer.delivery_method = :sendgrid_actionmailer
    config.action_mailer.sendgrid_actionmailer_settings = {
      api_key: ENV['SENDGRID_API_KEY'],
      raise_delivery_errors: false,
    }
  end

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = ::Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter

    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false
end
