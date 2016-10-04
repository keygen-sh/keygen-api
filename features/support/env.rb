require 'cucumber/rails'
require 'sidekiq/testing'
require 'faker'

ActionController::Base.allow_rescue = false

World FactoryGirl::Syntax::Methods

DatabaseCleaner.strategy = :transaction
