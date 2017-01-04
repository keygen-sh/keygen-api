source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '~> 5.0'
gem 'pg'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-attack'
gem 'rack-cors'

# JSON API serializers
gem 'active_model_serializers'
gem 'jsonapi-rails', git: "https://github.com/ezekg/jsonapi-rails"

# Billing and subscriptions
gem 'stripe'

# Authorization
gem 'pundit'

# Scopes and pagination
gem 'has_scope'
gem 'kaminari'

# Background jobs
gem 'sidekiq'
gem 'sidekiq-status'

# HTTP requests
gem 'httparty'

# State machine
gem 'aasm'

# Email templating
gem 'premailer-rails'
gem 'haml-rails'
gem 'sass-rails'

# Exception reporting
gem 'raygun4ruby'

group :development, :test do
  gem 'byebug', platform: :mri
  gem 'dotenv-rails'
  gem 'timecop'
  gem 'annotate'
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
