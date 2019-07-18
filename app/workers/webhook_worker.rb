# frozen_string_literal: true

require "httparty"

class WebhookWorker
  MAX_RESPONSE_BODY_BYTE_SIZE = 2048
  ACCEPTABLE_CODES = (200..299).freeze

  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include Signable

  sidekiq_options queue: :webhooks, retry: 15
  sidekiq_retry_in do |count|
    (count ** 4) + (10.minutes.to_i * rand(1..10))
  end

  def perform(account_id, event_id, endpoint_id, payload)
    account = Rails.cache.fetch(Account.cache_key(account_id), expires_in: 15.minutes) do
      Account.find account_id
    end

    endpoint = account.webhook_endpoints.find endpoint_id
    event = account.webhook_events.find event_id

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

    # TODO(ezekg) Remove this error handling after we know everything is working
    begin
      body =
        if "#{res.body}".bytesize > MAX_RESPONSE_BODY_BYTE_SIZE
          'RES_BODY_TOO_LARGE'
        else
          res.body
        end

      event.update(
        last_response_code: res.code,
        last_response_body: body
      )
    rescue => e
      Raygun.track_exception e

      raise e
    end

    if !ACCEPTABLE_CODES.include?(res.code)
      raise FailedRequestError
    end
  rescue OpenSSL::SSL::SSLError # Endpoint's SSL certificate is not showing as valid
    event.update(
      last_response_code: nil,
      last_response_body: 'SSL_ERROR'
    )
  rescue Net::ReadTimeout, Net::OpenTimeout # Our request to the endpoint timed out
    event.update(
      last_response_code: nil,
      last_response_body: 'REQ_TIMEOUT'
    )
  rescue Errno::ECONNREFUSED # Stop sending requests when the connection is refused
    event.update(
      last_response_code: nil,
      last_response_body: 'CONN_REFUSED'
    )
  rescue SocketError # Stop sending requests if DNS is no longer working for endpoint
    event.update(
      last_response_code: nil,
      last_response_body: 'DNS_ERROR'
    )
  end

  class FailedRequestError < StandardError; end
  class Request
    include HTTParty
  end
end
