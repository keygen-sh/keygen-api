# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.6.5'

gem 'rails', '~> 5.2'
gem 'pg'
gem 'puma', '~> 4.3.5'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'rack-attack', '~> 5.2'
gem 'rack-cors'

# Redis for caching and background jobs
gem 'redis'
gem 'hiredis'

# JSON API serializers
gem 'json', '~> 2.3.0'
gem 'jsonapi-rails', '0.3.1'
gem 'oj'

# Billing and subscriptions
gem 'stripe'

# Authorization
gem 'pundit'

# Cryptography
gem 'openssl'
gem 'jwt'

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

# HTTP requests
gem 'httparty'

# State machine
gem 'aasm', '~> 5.0.3'

# Email templating
gem 'premailer-rails'
gem 'haml-rails'
gem 'sass-rails'

# Logging
gem 'lograge'

# Exception reporting
gem 'raygun4ruby', "~> 1.1.11"

# Monitoring/APM
gem 'rails_autoscale_agent'
gem 'scout_apm', '~> 2.6.0'
gem 'barnes'

# Dyno management
gem 'whacamole'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'timecop'
  gem 'bullet'
  gem 'parallel_tests'
end

group :development do
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :test do
  gem 'stripe-ruby-mock', '~> 2.3.1', require: 'stripe_mock'
  gem 'cucumber-rails', require: false
  gem 'rspec-rails', '~> 3.5'
  gem 'rspec-expectations'
  gem 'factory_girl_rails', '4.8.0'
  gem 'database_cleaner'
  gem 'faker', '~> 2.14.0'
end
