require "httparty"

###
# DEPRECATED(ezekg) Use WebhookWorker instead
###
class SignedWebhookWorker
  ACCEPTABLE_STATUSES = (200..299).freeze

  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include Signable

  sidekiq_options queue: :webhooks, retry: 15

  def perform(account_id, endpoint_id, payload)
    account = Account.find account_id
    endpoint = account.webhook_endpoints.find endpoint_id

    res = Request.post(endpoint.url, {
      headers: {
        "Content-Type" => "application/json",
        "X-Signature" => sign(
          key: account.private_key,
          data: payload
        )
      },
      body: payload
    })

    if !ACCEPTABLE_STATUSES.include?(res.code)
      raise FailedRequestError
    end
  rescue SocketError # Stop sending requests if DNS is no longer working for endpoint
    nil
  end

  class FailedRequestError < StandardError; end
  class Request
    include HTTParty
  end
end
