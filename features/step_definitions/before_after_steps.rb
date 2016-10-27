World Rack::Test::Methods

Before "@api/v1" do
  @api_version = "v1"
end

Before do
  StripeHelper.start
end

After do |s|
  Sidekiq::Worker.clear_all
  StripeHelper.stop

  # Tell Cucumber to quit if a scenario fails
  if s.failed?
    puts last_request.url, last_response.status, last_response.body
    Cucumber.wants_to_quit = true
  end
end
