# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.1.1'

gem 'rails', '~> 7.0.2.3'
gem 'pg', '~> 1.3.4'
gem 'puma', '~> 5.6.2'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'rack-attack', '~> 6.6'
gem 'rack-cors'

# Redis for caching and background jobs
gem 'redis'

# JSON API serializers
gem 'json', '~> 2.3.0'
gem 'jsonapi-rails', '0.4.0'
gem 'oj'

# Billing and subscriptions
gem 'stripe', '~> 5.43'

# Authorization
gem 'pundit'

# Cryptography
gem 'openssl', '~> 2.2.1'
gem 'ed25519'
gem 'jwt'

# 2FA/TOTP
gem 'rotp', '~> 6.2'

# Scopes and pagination
gem 'has_scope'
gem 'kaminari', '~> 1.2.0'

# Postgres extensions
gem 'active_record_union'

# Background jobs
gem 'sidekiq', '~> 6.4'
gem 'sidekiq-unique-jobs', '~> 7.1.15'
gem 'sidekiq-status', '~> 2.1.3'
gem 'sidekiq-cron', github: 'citusdata/sidekiq-cron', ref: '56b3d32aeedeb5dfdebbf498d0079dbb0bbee890'
gem 'sidekiq-throttled'
gem 'sidekiq-cronitor', '~> 2.0'

# HTTP requests
gem 'httparty'

# State machine
gem 'aasm', '~> 5.0.3'

# Emails
gem 'sendgrid-ruby'
gem 'sendgrid-actionmailer'

# Email templating
gem 'sprockets', '~> 3.0'
gem 'premailer-rails'
gem 'haml-rails'
gem 'sass-rails'

# Logging
gem 'lograge'

# Dist
gem 'aws-sdk-s3', '~> 1'
gem 'semverse'

group :production do
  # Monitoring/APM
  gem 'rails_autoscale_agent'
  gem 'barnes'

  # Dyno management
  gem 'whacamole'
end

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'timecop', '~> 0.9.5'
  gem 'bullet', '~> 7.0.1'
  gem 'parallel_tests', '~> 3.8'
end

group :development do
  gem 'listen', '~> 3.0.5'
end

group :test do
  gem 'stripe-ruby-mock', '~> 3.1.0.rc3', require: 'stripe_mock'
  gem 'cucumber-rails', '~> 2.5', require: false
  gem 'rspec-rails', '~> 5.1.1'
  gem 'rspec-expectations', '~> 3.11'
  gem 'factory_bot_rails', '~> 6.2'
  gem 'database_cleaner', '~> 2.0'
  gem 'faker', '~> 2.20.0'
  gem 'webmock', '~> 3.14.0'
end
