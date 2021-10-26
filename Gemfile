# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.4'

gem 'rails', '~> 6.1.4.1'
gem 'pg'
gem 'puma', '~> 5.5.1'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'rack-attack', '~> 5.2'
gem 'rack-cors'

# Redis for caching and background jobs
gem 'redis'
gem 'hiredis'

# JSON API serializers
gem 'json', '~> 2.3.0'
gem 'jsonapi-rails', '0.4.0'
gem 'oj'

# XML serializers
gem 'ox'

# Billing and subscriptions
gem 'stripe'

# Authorization
gem 'pundit'

# Cryptography
gem 'openssl'
gem 'ed25519'
gem 'jwt'

# 2FA/TOTP
gem 'rotp'

# Scopes and pagination
gem 'has_scope'
gem 'kaminari', '~> 1.2.0'

# Search
gem 'pg_search'

# Background jobs
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-status'
gem 'sidekiq-cron'
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
  gem 'timecop'
  gem 'bullet'
  gem 'parallel_tests', '~> 3.3'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'stripe-ruby-mock', '~> 2.3.1', require: 'stripe_mock'
  gem 'cucumber-rails', '~> 2.2', require: false
  gem 'rspec-rails', '~> 3.5'
  gem 'rspec-expectations'
  gem 'factory_girl_rails', '4.8.0'
  gem 'database_cleaner'
  gem 'faker', '~> 2.14.0'
  gem 'webmock'
end
