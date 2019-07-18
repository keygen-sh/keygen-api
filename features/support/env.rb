# frozen_string_literal: true

require 'cucumber/rspec/doubles'
require 'cucumber/rails'
require 'bullet'
require 'faker'

ActionController::Base.allow_rescue = false

DatabaseCleaner.strategy = :transaction

World FactoryGirl::Syntax::Methods
