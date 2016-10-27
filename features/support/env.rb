require 'cucumber/rails'
require 'faker'

ActionController::Base.allow_rescue = false

DatabaseCleaner.strategy = :transaction

World FactoryGirl::Syntax::Methods
