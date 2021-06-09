# frozen_string_literal: true

require "httparty"

class WebhookWorker
  MAX_RESPONSE_BODY_BYTE_SIZE = 2048
  ACCEPTABLE_CODES = (200..299).freeze

  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  include SignatureHeaders

  sidekiq_options queue: :webhooks, retry: 15, lock: :until_executed, dead: false
  sidekiq_retry_in do |count|
    (count ** 4) + (10.minutes.to_i * rand(1..10))
  end

  def perform(account_id, event_id, endpoint_id, payload)
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find(account_id)
    end

    endpoint = account.webhook_endpoints.find_by(id: endpoint_id)
    return if endpoint.nil?

    event = account.webhook_events.find_by(id: event_id)
    return if event.nil?

    event_type = event.event_type
    return unless endpoint.subscribed?(event_type.event)

    date     = Time.current
    httpdate = date.httpdate
    uri      = URI.parse(endpoint.url)
    digest   = generate_digest_header(body: payload)
    sig      = generate_signature_header(
      account: account,
      algorithm: endpoint.signature_algorithm.presence || :ed25519,
      keyid: nil,
      date: httpdate,
      method: 'POST',
      host: uri.host,
      uri: [uri.path.presence || '/', uri.query.presence].compact.join('?'),
      digest: digest,
    )

    headers = {
      'Content-Type' => 'application/json',
      'Date' => httpdate,
      'Digest' => digest,
      'Keygen-Signature' => sig,
    }

    # NOTE(ezekg) Legacy signatures are deprecated
    headers['X-Signature'] = sign_response_data(algorithm: :legacy, account: account, data: payload) if
      account.created_at < SignatureHeaders::LEGACY_SIGNATURE_UNTIL

    res = Request.post(endpoint.url, {
      write_timeout: 15.seconds.to_i,
      read_timeout: 15.seconds.to_i,
      open_timeout: 15.seconds.to_i,
      headers: headers,
      body: payload,
    })

    # TODO(ezekg) Remove this error handling after we know everything is working
    begin
      body =
        if "#{res.body}".bytesize > MAX_RESPONSE_BODY_BYTE_SIZE
          'RES_BODY_TOO_LARGE'
        else
          res.body
        end

      event.update!(
        last_response_code: res.code,
        last_response_body: body
      )
    rescue => e
      Keygen.logger.exception e

      raise e
    end

    if !ACCEPTABLE_CODES.include?(res.code)
      case event
      in endpoint: /\.ngrok\.io/, last_response_code: 404, last_response_body: /tunnel .+?\.ngrok\.io not found/i
        Keygen.logger.warn "[webhook_worker] Disabling dead ngrok endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        # Automatically disable dead ngrok tunnel endpoints
        endpoint.disable!

        return
      in endpoint: /\.ngrok\.io/, last_response_code: 504
        Keygen.logger.warn "[webhook_worker] Skipping retries for bad ngrok endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        return
      in endpoint: /\.loca\.lt/, last_response_code: 504
        Keygen.logger.warn "[webhook_worker] Skipping retries for bad localtunnel endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        return
      else
        Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        raise FailedRequestError
      end
    end

    Keygen.logger.info "[webhook_worker] Delivered webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"
  rescue OpenSSL::SSL::SSLError # Endpoint's SSL certificate is not showing as valid
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=SSL_ERROR"

    event.update!(
      last_response_code: nil,
      last_response_body: 'SSL_ERROR'
    )
  rescue Net::WriteTimeout, # Our request to the endpoint timed out
         Net::ReadTimeout,
         Net::OpenTimeout
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=REQ_TIMEOUT"

    event.update!(
      last_response_code: nil,
      last_response_body: 'REQ_TIMEOUT'
    )
  rescue Errno::ECONNREFUSED # Stop sending requests when the connection is refused
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=CONN_REFUSED"

    event.update!(
      last_response_code: nil,
      last_response_body: 'CONN_REFUSED'
    )
  rescue SocketError # Stop sending requests if DNS is no longer working for endpoint
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=DNS_ERROR"

    event.update!(
      last_response_code: nil,
      last_response_body: 'DNS_ERROR'
    )
  end

  class FailedRequestError < StandardError; end
  class Request
    include HTTParty
  end
end
