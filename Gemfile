# frozen_string_literal: true

source 'https://rubygems.org'
ruby '3.4.7'

gem 'rails', '~> 8.1.2'
gem 'pg', '~> 1.3.4'
gem 'puma', '~> 6.6'
gem 'bcrypt', '3.1.17'
gem 'rack', '~> 2.2.22'
gem 'rack-timeout', '~> 0.7', require: 'rack/timeout/base'
unless ENV.key?('NO_RACK_ATTACK')
  gem 'rack-attack', '~> 6.6'
end
gem 'rack-cors'
gem 'uri', '>= 0.12.2'
gem 'ostruct'

# Redis for caching and background jobs
gem 'redis', '~> 4.7.1'

# API migrations
gem 'request_migrations', '~> 1.1.2'

# API params
gem 'typed_params', '~> 1.4.1'

# Serializers
gem 'json', '~> 2.3.0'
gem 'jsonapi-rails', '0.4.0'
gem 'oj'
gem 'nokogiri', '~> 1.16.5'
gem 'msgpack', '~> 1.7'

# Billing and subscriptions
gem 'stripe', '~> 5.43'

# Authentication
gem 'rotp', '~> 6.2'
gem 'workos', '~> 5.26'

# Authorization
gem 'action_policy', '~> 0.7.5'

# Cryptography
gem 'openssl', '~> 3.1.0'
gem 'ed25519'
gem 'jwt'

# Scopes and pagination
gem 'has_scope'
gem 'kaminari', '~> 1.2.0'

# Postgres/DB extensions
gem 'active_record_union', github: 'brianhempel/active_record_union', ref: '8ebe558709aabe039abd24e3e7dd4d4354a6de88'
gem 'active_record_distinct_on', '~> 1.7'
gem 'activerecord_where_assoc', '~> 1.2'
gem 'ar_lazy_preload', '~> 2.0'
gem 'strong_migrations'
gem 'verbose_migrations'
gem 'temporary_tables'
gem 'statement_timeout', '~> 1.1'
gem 'union_of'
gem 'order_as_specified'
gem 'clickhouse-activerecord', github: 'keygen-sh/clickhouse-activerecord', ref: '88af993830c84c12b8c86c34d0520a8363f499da'

# Pattern matching
gem 'rails-pattern_matching'

# Background jobs
gem 'sidekiq', '~> 7.3'
gem 'sidekiq-cron', '~> 1.12.0'
gem 'sidekiq-cronitor', '~> 3.8.0'

# HTTP requests
gem 'httparty', '~> 0.22.0'

# State machine
gem 'aasm', '~> 5.0.3'

# Emails
gem 'sendgrid-ruby'
gem 'sendgrid-actionmailer'

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
gem 'compact_index'
gem 'minitar'

# Misc
gem 'null_association'
gem 'email_check'
gem 'haikunator'

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
  gem 'bullet', '~> 8'
  gem 'parallel_tests', '~> 5.5'
  gem 'cuke_modeler', '~> 3.19' # for running `parallel_test --group-by scenarios`
  gem 'faker', '~> 2.20.0'
end

group :development do
  gem 'listen', '>= 3.8.0'
  gem 'tracer'
end

group :test do
  gem 'stripe-ruby-mock', github: 'stripe-ruby-mock/stripe-ruby-mock', ref: '6ceea9679bb573cb8bc6830f1bdf670b220a9859', require: 'stripe_mock'
  gem 'cucumber', '~> 10.2'
  gem 'cucumber-rails', '~> 4', require: false
  gem 'rspec-rails', '~> 8'
  gem 'rspec-expectations', '~> 3.13'
  gem 'anbt-sql-formatter'
  gem 'factory_bot_rails', '~> 6.5'
  gem 'database_cleaner', '~> 2.1'
  gem 'database_cleaner-active_record', '~> 2.2'
  gem 'webmock', '~> 3.25'
  gem 'memory_profiler'
end
