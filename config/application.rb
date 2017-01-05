require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Keygen
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

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

    # Protect against DDOS
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
