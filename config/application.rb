# frozen_string_literal: true

require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'rails/test_unit/railtie'

require_relative '../lib/keygen'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require *Rails.groups

module Keygen
  class Application < Rails::Application
    config.load_defaults 7.0

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

    # Ignore X-Forwarded-For header
    config.middleware.insert_before 0, Keygen::Middleware::IgnoreForwardedHost

    # FIXME(ezekg) Catch any JSON/URI parse errors, routing errors, etc. We're
    #              inserting this middleware twice because Rails is stupid and
    #              emits errors at multiple layers in the stack, resulting
    #              in this ugly hack.
    config.middleware.insert_before 0, Keygen::Middleware::RequestErrorWrapper

    # Add a default JSON content type
    config.middleware.use Keygen::Middleware::DefaultContentType

    # Protect against DDOS and other abuses
    config.middleware.use Rack::Attack

    # See above comment about having to use this multiple
    config.middleware.use Keygen::Middleware::RequestErrorWrapper

    # FIXME(ezekg) Should we migrate to credentials?
    config.active_record.encryption.primary_key         = ENV.fetch('ENCRYPTION_PRIMARY_KEY')
    config.active_record.encryption.deterministic_key   = ENV.fetch('ENCRYPTION_DETERMINISTIC_KEY')
    config.active_record.encryption.key_derivation_salt = ENV.fetch('ENCRYPTION_KEY_DERIVATION_SALT')

    # TODO(ezekg) Remove these once our data is migrated
    config.active_record.encryption.support_unencrypted_data = true
    config.active_record.encryption.extend_queries           = true

    # Update async destroy batch size
    # TODO(ezekg) Will be introduced in Rails 7.1
    # config.active_record.destroy_association_async_batch_size = 100

    # We don't need this: https://guides.rubyonrails.org/security.html#unsafe-query-generation
    config.action_dispatch.perform_deep_munge = false

    # Add support for trusted proxies
    config.action_dispatch.trusted_proxies =
      ActionDispatch::RemoteIp::TRUSTED_PROXIES + ENV.fetch('TRUSTED_PROXIES') { '' }
                                                     .split(',')
                                                     .map { IPAddr.new(_1.strip) }

    # Use mailers queue
    config.action_mailer.deliver_later_queue_name = :mailers

    # Use Sidekiq for background jobs
    config.active_job.queue_adapter = :sidekiq

    # Include all helpers
    config.action_controller.include_all_helpers = true

    # Force UTF-8 encoding
    config.encoding = 'utf-8'

    # Add services/validators to autoload path
    config.autoload_paths += %W[
      #{config.root}/app/serializers
      #{config.root}/app/validators
      #{config.root}/app/services
    ]

    # Print env info when server boots
    config.after_initialize do |app|
      app.default_url_options = {
        host: ENV.fetch('KEYGEN_HOST'),
        protocol: 'https',
      }

      Keygen::Console.welcome!
    end
  end
end
