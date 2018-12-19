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
    config.middleware.delete Rack::Sendfile
    config.middleware.delete Rack::Runtime

    # Log Rack request/response to datebase
    config.middleware.insert_before 0, Keygen::Middleware::RequestLogger
    config.middleware.insert_before 0, Keygen::Middleware::RequestStore

    # FIXME(ezekg) Catch any JSON/URI parse errors, routing errors, etc. We're
    #              inserting this middleware twice because Rails is stupid and
    #              emits this error at multiple layers in the stack, resulting
    #              in this ugly hack.
    config.middleware.insert_before 0, Keygen::Middleware::RequestErrorWrapper
    config.middleware.use Keygen::Middleware::RequestErrorWrapper

    # Add a default JSON content type
    config.middleware.use Keygen::Middleware::DefaultContentType

    # Protect against DDOS and other abuses
    config.middleware.use Rack::Attack

    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Add services/validators to autoload path
    config.autoload_paths += %W[
      #{config.root}/app/validators
      #{config.root}/app/services
    ]
  end
end
