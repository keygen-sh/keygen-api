source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '~> 5.0'
gem 'pg'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'rack-attack'
gem 'rack-cors'

# Hashed record IDs
gem 'hashid-rails'

# JSON API serializers
gem 'active_model_serializers'
gem 'jsonapi-rails'

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

# Friendly IDs
gem 'friendly_id'

# Soft-deletion of database records
gem 'paranoia', '~> 2.2'

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
