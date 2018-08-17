source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '~> 5.0'
gem 'pg'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-attack', '~> 5.2'
gem 'rack-cors'

# Redis for caching and background jobs
gem 'redis-rails'
gem 'redis', '~> 3.3.3'

# JSON API serializers
gem 'jsonapi-rails', '0.3.1'

# Billing and subscriptions
gem 'stripe'

# Authorization
gem 'pundit'

# Scopes and pagination
gem 'has_scope'
gem 'groupdate'
gem 'kaminari'

# Search
gem 'pg_search'

# Background jobs
gem 'sidekiq'
gem 'sidekiq-unique-jobs'
gem 'sidekiq-status'
gem 'sidekiq-cron'

# HTTP requests
gem 'httparty'

# State machine
gem 'aasm'

# Email templating
gem 'premailer-rails'
gem 'haml-rails'
gem 'sass-rails'

# Exception reporting
gem 'raygun4ruby', "~> 1.1.11"

# Monitoring/APM
gem 'newrelic_rpm'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'timecop'
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
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'faker', '~> 1.6.3'
end
