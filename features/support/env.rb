# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../config/environment', __FILE__)
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'database_cleaner'
require 'database_cleaner/active_record'

# FIXME(ezekg) see: https://github.com/DatabaseCleaner/database_cleaner/issues/419#issuecomment-201949198
Rails.application.eager_load!

DatabaseCleaner[:active_record, db: :primary].strategy    = :transaction
DatabaseCleaner[:active_record, db: :clickhouse].strategy = :truncation

# FIXME(ezekg) cucumber-rspec doesn't play well with multiple databases
class World < ActionDispatch::IntegrationTest
  include ActiveSupport::Testing::SetupAndTeardown
  include Rack::Test::Methods
  include RSpec::Matchers

  def initialize = super('Cucumber World')
end

World do
  World.new
end

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end
