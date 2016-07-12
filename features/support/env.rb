require 'cucumber/rails'
# require "json_spec/cucumber"
require 'faker'

ActionController::Base.allow_rescue = false

World FactoryGirl::Syntax::Methods

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end
