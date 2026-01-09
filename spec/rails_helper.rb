# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'support/factory_bot'
require 'database_cleaner'
require 'database_cleaner/active_record'
require 'sidekiq/testing'
require 'request_migrations/testing'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require(f) }

# Requires shared examples.
Dir[Rails.root.join('spec/shared/**/*.rb')].each { |f| require(f) }

# FIXME(ezekg) see: https://github.com/DatabaseCleaner/database_cleaner/issues/419#issuecomment-201949198
Rails.application.eager_load!

# clear database tables after each test
DatabaseCleaner[:active_record].strategy                  = :transaction # covers e.g. :primary
DatabaseCleaner[:active_record, db: :clickhouse].strategy = :truncation

RSpec.configure do |config|
  econfig = RSpec::Expectations.configuration

  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper
  config.include FactoryBot::Syntax::Methods
  config.include TemporaryTables::Methods
  config.include Rails.application.routes.url_helpers
  config.include AuthorizationHelper, type: :policy
  config.include ApplicationHelper
  config.include EnvironmentHelper
  config.include FileHelper
  config.include TimeHelper
  config.include EnvHelper
  config.include KeygenHelper
  config.include TaskHelper
  config.include MutexHelper

  # # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"
  #
  # # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # # examples within a transaction, remove the following line or assign false
  # # instead of true.
  # config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # skip logging pending/skipped examples
  config.pending_failure_output = :skip

  # Stub keygens
  config.before { stub_everything! }

  # Setup Sidekiq, Stripe, etc.
  config.before :each do
    DatabaseCleaner.start
    RequestMigrations::Testing.setup!
    Sidekiq::Testing.fake!
    StripeHelper.start
  end

  # Teardown Stripe, clean database, etc.
  config.after :each do
    RequestMigrations::Testing.teardown!
    Faker::UniqueGenerator.clear
    StripeHelper.stop
    DatabaseCleaner.clean
  end

  # Make sure we're working with a prestine ENV in EE tests.
  config.around type: :ee do |example|
    with_prestine_env(&example)
  end

  # hooks to run/skip tests for a certain edition
  config.around skip: :ce do |example|
    if Keygen.ce?
      skip 'skipped in CE'
    else
      example.run
    end
  end

  config.around skip: :ee do |example|
    if Keygen.ee?
      skip 'skipped in EE'
    else
      example.run
    end
  end

  config.around only: :ce do |example|
    if Keygen.ce?
      example.run
    else
      skip 'skipped in EE'
    end
  end

  config.around only: :ee do |example|
    if Keygen.ee?
      example.run
    else
      skip 'skipped in CE'
    end
  end

  config.around :each, :skip_ce do |example|
    if Keygen.ce?
      skip 'skipped in CE'
    else
      example.run
    end
  end

  config.around :each, :skip_ee do |example|
    if Keygen.ee?
      skip 'skipped in EE'
    else
      example.run
    end
  end

  config.around :each, :only_ce do |example|
    if Keygen.ce?
      example.run
    else
      skip 'skipped in EE'
    end
  end

  config.around :each, :only_ee do |example|
    if Keygen.ee?
      example.run
    else
      skip 'skipped in CE'
    end
  end

  # disable implicit transaction for cleaning up after tests (mainly to facilitate threading)
  config.around :each, :skip_transaction_cleaner do |example|
    DatabaseCleaner[:active_record].strategy = [:truncation, except: %w[event_types permissions]]

    example.run
  ensure
    DatabaseCleaner[:active_record].strategy = :transaction
  end

  # ignore false positives e.g. to_not raise_error SomeError
  config.around :each, :ignore_potential_false_positives do |example|
    on_potential_false_positives_was, econfig.on_potential_false_positives = econfig.on_potential_false_positives, :nothing

    example.run
  ensure
    econfig.on_potential_false_positives = on_potential_false_positives_was
  end

  # Reset license file and license before each EE test.
  config.before type: :ee do
    Keygen::EE::LicenseFile.reset!
    Keygen::EE::License.reset!
  end

  # Reset license file and license after each EE test.
  config.after type: :ee do
    Keygen::EE::LicenseFile.reset!
    Keygen::EE::License.reset!
  end

  # Load rake tasks once
  mu = MutexHelper::Once.new

  config.before type: :task do
    mu.synchronize do
      require 'rake'

      Rails.application.load_tasks
    end
  end
end
