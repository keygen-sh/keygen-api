require_relative 'boot'

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

require_relative "../lib/keygen/middleware"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require *Rails.groups

module Keygen
  class Application < Rails::Application
    config.generators do |generator|
      # Use UUIDs for table primary keys
      generator.orm :active_record, primary_key_type: :uuid
      # Skip test generation (we do it manually)
      generator.test_framework false
    end

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Remove unneeded Rack middleware
    config.middleware.delete Rack::ConditionalGet
    config.middleware.delete Rack::ETag

    # Protect against DDOS and other abuses
    config.middleware.use Rack::Attack

    # Log Rack request/response to datebase
    config.middleware.insert_before Rack::Runtime, Keygen::Middleware::RequestLogger

    # Catch JSON parse errors and return a better error message
    config.middleware.insert_before Rack::Runtime, Keygen::Middleware::CatchJsonParseErrors

    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Add services/validators to autoload path
    config.autoload_paths += %W[
      #{config.root}/app/validators
      #{config.root}/app/services
    ]
  end
end
