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

Before("@skip/prosopite") { Prosopite.enabled = false }
After("@skip/prosopite")  { Prosopite.enabled = true }

Before do |scenario|
  # Skip CE tests if we're running in an EE env, and vice-versa
  # for EE tests in a CE env.
  return skip_this_scenario if
    Keygen.ee? && scenario.tags.any? { _1.name == '@ce' } ||
    Keygen.ce? && scenario.tags.any? { _1.name == '@ee' }

  # Skip multiplayer if we're running in singleplayer mode,
  # and vice-versa for singleplayer in multiplayer mode.
  return skip_this_scenario if
    Keygen.singleplayer? && scenario.tags.any? { _1.name == '@mp' } ||
    Keygen.multiplayer? && scenario.tags.any? { _1.name == '@sp' }

  # And of course, skip if we need to skip.
  return skip_this_scenario if
    scenario.tags.any? { _1.name == '@skip' }

  ActionMailer::Base.deliveries.clear
  Sidekiq::Worker.clear_all
  StripeHelper.start
  Rails.cache.clear

  stub_account_keygens!
  stub_cache!
  stub_s3!

  @crypt = []
end

After do |scenario|
  Faker::UniqueGenerator.clear
  StripeHelper.stop

  # Tell Cucumber to quit if a scenario fails
  if scenario.failed?
    Cucumber.wants_to_quit = true

    log scenario.exception

    req_headers = last_request.env
      .select { |k, v| k.start_with?('HTTP_') }
      .transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') } rescue {}

    log JSON.pretty_generate(
      request: {
        method: last_request.request_method,
        url: last_request.url,
        headers: req_headers,
        body: (JSON.parse(last_request.body.string) rescue nil)
      },
      response: {
        status: last_response.status,
        headers: (last_response.headers.to_h rescue {}),
        body: (JSON.parse(last_response.body) rescue last_response.body)
      },
      debug: {
        env_number: ENV['TEST_ENV_NUMBER'].to_i,
        query_log: Elif.open(Rails.root / 'log' / 'test.log') do |log|
          count = ENV.fetch('TEST_DEBUG_QUERY_LOG_LINE_COUNT') { 5 }.to_i
          lines = []

          # Read the last n SQL lines from the log file (useful when debugging CI)
          log.each do |line|
            break if lines.count >= count

            if line =~ /application:Keygen,pid:#{Process.pid}/
              lines << line.squish
            end
          end

          lines
        rescue
          lines
        end
      },
    )
  end

  @account = nil
  @token = nil
end

AfterAll { Rails.cache.clear }
