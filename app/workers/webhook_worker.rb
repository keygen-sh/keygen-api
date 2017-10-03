require "httparty"

class WebhookWorker
  ACCEPTABLE_STATUSES = (200..299).freeze

  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options queue: :webhooks, retry: 15

  def perform(endpoint, payload)
    request = Request.post(endpoint, {
      headers: { "Content-Type" => "application/json" },
      body: payload
    })

    if !ACCEPTABLE_STATUSES.include?(request.code)
      raise FailedRequestError
    end
  end

  class FailedRequestError < StandardError; end
  class Request
    include HTTParty
  end
end
