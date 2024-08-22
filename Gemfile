# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.3.4'

gem 'rails', '~> 7.2.0-rc1'
gem 'pg', '~> 1.3.4'
gem 'puma', '~> 6.4.2'
gem 'bcrypt', '~> 3.1.7'
gem 'rack', '~> 2.2.8.1'
gem 'rack-timeout', require: 'rack/timeout/base'
unless ENV.key?('NO_RACK_ATTACK')
  gem 'rack-attack', '~> 6.6'
end
gem 'rack-cors'
gem 'uri', '>= 0.12.2'

# Redis for caching and background jobs
gem 'redis', '~> 4.7.1'

# API migrations
gem 'request_migrations', '~> 1.1'

# API params
gem 'typed_params', '~> 1.2.5'

# Serializers
gem 'json', '~> 2.3.0'
gem 'jsonapi-rails', '0.4.0'
gem 'oj'
gem 'nokogiri', '~> 1.16.5'
gem 'msgpack', '~> 1.7'

# Billing and subscriptions
gem 'stripe', '~> 5.43'

# Authorization
gem 'action_policy', '~> 0.6.3'

# Cryptography
gem 'openssl', '~> 3.1.0'
gem 'ed25519'
gem 'jwt'

# 2FA/TOTP
gem 'rotp', '~> 6.2'

# Scopes and pagination
gem 'has_scope'
gem 'kaminari', '~> 1.2.0'

# Postgres/DB extensions
gem 'active_record_union'
gem 'active_record_distinct_on', '~> 1.6'
gem 'activerecord_where_assoc', '~> 1.1.5'
gem 'ar_lazy_preload', '~> 2.0'
gem 'strong_migrations'

# Pattern matching
gem 'rails-pattern_matching'

# Background jobs
gem 'sidekiq', '~> 7.2.4'
gem 'sidekiq-cron', '~> 1.12.0'
gem 'sidekiq-cronitor', '~> 3.6.0'

# HTTP requests
gem 'httparty', '~> 0.22.0'

# State machine
gem 'aasm', '~> 5.0.3'

# Emails
gem 'sendgrid-ruby'
gem 'sendgrid-actionmailer'

# Email templating
gem 'sprockets', '~> 3.0'
gem 'premailer', '~> 1.23.0'
gem 'premailer-rails'
gem 'haml-rails'
gem 'sass-rails'

# Monitoring/APM
unless ENV.key?('NO_SENTRY')
  gem 'stackprof'
  gem 'sentry-ruby'
  gem 'sentry-rails'
  gem 'sentry-sidekiq'
end

# Logging
gem 'lograge'

# Dist
gem 'aws-sdk-s3', '~> 1'
gem 'semverse'

group :production do
  # Monitoring/APM
  gem 'barnes'

  # Autoscaling
  unless ENV.key?('NO_JUDOSCALE') || ENV.key?('NO_RAILS_AUTOSCALE')
    gem 'judoscale-rails', '~> 1.5.4'
    gem 'judoscale-sidekiq', '~> 1.5.4'
  end
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'timecop', '~> 0.9.5'
  gem 'bullet', '~> 7.2'
  gem 'parallel_tests', '~> 4.2.1'
  gem 'cuke_modeler', '~> 3.19' # for running `parallel_test --group-by scenarios`
  gem 'faker', '~> 2.20.0'
end

group :development do
  gem 'listen', '>= 3.8.0'
  gem 'tracer'
end

group :test do
  gem 'stripe-ruby-mock', github: 'stripe-ruby-mock/stripe-ruby-mock', ref: '6ceea9679bb573cb8bc6830f1bdf670b220a9859', require: 'stripe_mock'
  gem 'cucumber-rails', '~> 2.5', require: false
  gem 'rspec-rails', '~> 6.1.3'
  gem 'rspec-expectations', '~> 3.13'
  gem 'anbt-sql-formatter'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'database_cleaner', '~> 2.0'
  gem 'webmock', '~> 3.14.0'
  gem 'elif', '~> 0.1.0'
end
