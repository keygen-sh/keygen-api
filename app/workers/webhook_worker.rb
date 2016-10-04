require "httparty"

class WebhookWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options retry: 5, dead: false

  def perform(endpoint, payload)
    Request.post(endpoint, {
      headers: { "Content-Type" => "application/json" },
      body: payload
    })
  end

  class Request
    include HTTParty
  end
end
