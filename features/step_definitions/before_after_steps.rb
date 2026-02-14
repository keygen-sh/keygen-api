# frozen_string_literal: true

World Rack::Test::Methods

RequestMigrations.supported_versions.each do |version|
  semver = Semverse::Version.new(version)

  Before "@api/v#{semver.major}.#{semver.minor}" do
    @api_version = "v#{semver.major}"
  end

  Before "@api/v#{semver.major}" do
    @api_version = "v#{semver.major}"
  end
end

Before '@api/priv' do
  @api_version = '-' # private api prefix
end

# FIXME(ezekg) This is super hacky but there's no easy way to disable
#              bullet outside of adding controller filters
Before("@skip/bullet") { Bullet.instance_variable_set :@enable, false }
After("@skip/bullet")  { Bullet.instance_variable_set :@enable, true }

# make sure we always have a clean slate
BeforeAll do
  DatabaseCleaner.clean_with :truncation, except: %w[event_types permissions]
  Rails.cache.clear
end

# run subset of active jobs inline so data is immediately available
ACTIVE_JOBS_TO_RUN_INLINE = [
  ActiveRecord::DestroyAssociationAsyncJob,
  DualWrites::BulkReplicationJob,
  DualWrites::ReplicationJob,
  AsyncDestroyable::DestroyAsyncJob,
  AsyncCreatable::CreateAsyncJob,
  AsyncUpdatable::UpdateAsyncJob,
  AsyncTouchable::TouchAsyncJob,
]

Around do |_, scenario|
  adapter_was, ActiveJob::Base.queue_adapter = ActiveJob::Base.queue_adapter, :test

  perform_enqueued_jobs only: ACTIVE_JOBS_TO_RUN_INLINE do
    scenario.call
  end
ensure
  ActiveJob::Base.queue_adapter = adapter_was
end

Before do |scenario|
  # Skip CE tests if we're running in an EE env, and vice-versa
  # for EE tests in a CE env.
  return skip_this_scenario if
    Keygen.ee? && scenario.tags.any? { it.name == '@ce' } ||
    Keygen.ce? && scenario.tags.any? { it.name == '@ee' }

  # Skip multiplayer if we're running in singleplayer mode,
  # and vice-versa for singleplayer in multiplayer mode.
  return skip_this_scenario if
    Keygen.singleplayer? && scenario.tags.any? { it.name == '@mp' } ||
    Keygen.multiplayer? && scenario.tags.any? { it.name == '@sp' }

  # skip clickhouse-specific scenarios if disabled
  return skip_this_scenario if
    !Keygen.database.clickhouse_enabled? && scenario.tags.any? { it.name == '@clickhouse' }

  # And of course, skip if we need to skip.
  return skip_this_scenario if
    scenario.tags.any? { it.name == '@skip' }

  ActionMailer::Base.deliveries.clear
  Sidekiq::Worker.clear_all
  StripeHelper.start
  Rails.cache.clear
  DatabaseCleaner.start

  stub_everything!

  @crypt = []
end

After do |scenario|
  if scenario.failed?
    # print additional information about the failed scenario to stderr when debug mode is enabled
    if ENV.true?('DEBUG')
      warn ScenarioDebugger.call(scenario:, request: last_request, response: last_response)
    end
  end

  Faker::UniqueGenerator.clear
  StripeHelper.stop
  Current.reset
  DatabaseCleaner.clean rescue nil

  unfreeze_time

  @account = nil
  @bearer  = nil
  @token   = nil
end
