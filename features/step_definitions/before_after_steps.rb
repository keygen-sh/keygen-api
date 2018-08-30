World Rack::Test::Methods

Before "@api/v1" do
  @api_version = "v1"
end

Before do
  Bullet.start_request if Bullet.enable?

  ActionMailer::Base.deliveries.clear
  Sidekiq::Worker.clear_all
  StripeHelper.start

  @crypt = []
end

After do |s|
  Bullet.perform_out_of_channel_notifications if Bullet.enable? && Bullet.notification?
  Bullet.end_request if Bullet.enable?

  StripeHelper.stop

  # Tell Cucumber to quit if a scenario fails
  if s.failed?
    puts JSON.pretty_generate(
      request: {
        url: last_request.url,
        # headers: {
        #   authorization: last_request.get_header('Authorization')
        # },
        body: (JSON.parse(last_request.body.string) rescue nil)
      },
      response: {
        status: last_response.status,
        # headers: last_response.headers,
        body: (JSON.parse(last_response.body) rescue nil)
      }
    )
    Cucumber.wants_to_quit = true
  end
end
