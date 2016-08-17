require 'cucumber/rails'
# require "json_spec/cucumber"
require 'faker'

ActionController::Base.allow_rescue = false

World FactoryGirl::Syntax::Methods

DatabaseCleaner.strategy = :transaction
