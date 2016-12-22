World Rack::Test::Methods

Before "@api/v1" do
  @api_version = "v1"
end

Before do
  ActionMailer::Base.deliveries.clear
  Sidekiq::Worker.clear_all
  StripeHelper.start

  @crypt = []
end

After do |s|
  StripeHelper.stop

  # Tell Cucumber to quit if a scenario fails
  if s.failed?
    puts JSON.pretty_generate(
      request: { resource: last_request.url, body: (JSON.parse(last_request.body.string) rescue nil) },
      response: { status: last_response.status, body: (JSON.parse(last_response.body) rescue nil) }
    )
    Cucumber.wants_to_quit = true
  end
end
