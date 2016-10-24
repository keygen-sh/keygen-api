source 'https://rubygems.org'
ruby '2.3.1'

gem 'rails', '~> 5.0'
gem 'pg'
gem 'puma', '~> 3.0'
gem 'bcrypt', '~> 3.1.7'
gem 'hashid-rails'
gem 'rack-cors'
gem 'active_model_serializers'
gem 'rack-attack'
gem 'stripe'
gem 'haml-rails', '~> 0.9'
gem 'pundit'
gem 'has_scope'
gem 'kaminari'
gem 'sidekiq'
gem 'sidekiq-status'
gem 'httparty'

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
  gem 'factory_girl_rails'
  gem 'database_cleaner'
  gem 'faker', '~> 1.6.3'
end
