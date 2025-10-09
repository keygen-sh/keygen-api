# frozen_string_literal: true

require "httparty"

class WebhookWorker < BaseWorker
  include SignatureMethods

  MAX_RESPONSE_BODY_BYTE_SIZE = 2048
  ACCEPTABLE_CODES = (200..299).freeze

  sidekiq_options queue: :webhooks,
                  retry: 15,
                  dead: false

  sidekiq_retry_in do |count|
    jitter = 10.minutes.to_i * rand(1..10)

    (count ** 4) + jitter
  end

  sidekiq_retries_exhausted do |job|
    account_id, event_id, endpoint_id, payload = job['args']

    event = WebhookEvent.find_by(account_id: account_id, id: event_id)
    next if
      event.nil?

    event.update(status: 'FAILED')
  end

  def perform(account_id, event_id, endpoint_id, event_data)
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find(account_id)
    end

    endpoint = account.webhook_endpoints.find_by(id: endpoint_id)
    return if
      endpoint.nil?

    event = account.webhook_events.find_by(id: event_id)
    return if
      event.nil?

    event_type = event.event_type
    return unless
      endpoint.subscribed?(event_type.event)

    # migrate event payload in case anything has changed e.g. endpoint API version
    current_version = event.api_version || CURRENT_API_VERSION
    target_version  = endpoint.api_version || account.api_version
    migrator        = RequestMigrations::Migrator.new(
      from: current_version,
      to: target_version,
    )

    body =
      case e = JSON.parse(event_data, symbolize_names: true)
      in data: { type: 'webhook-events', attributes: { payload: json } }
        data = JSON.parse(json, symbolize_names: true)

        migrator.migrate!(data:)

        # Re-encode event payload
        e[:data][:attributes][:payload] = JSON.generate(data)

        # Re-encode event
        JSON.generate(e)
      end

    # Sign payload
    date     = Time.current
    httpdate = date.httpdate
    uri      = URI.parse(endpoint.url)
    digest   = generate_digest_header(body:)
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
      'User-Agent' => "Keygen/#{target_version} (+https://keygen.sh/docs/api/webhooks/)",
      'Content-Type' => 'application/json',
      'Date' => httpdate,
      'Digest' => digest,
      'Keygen-Date' => httpdate,
      'Keygen-Digest' => digest,
      'Keygen-Signature' => sig,
      'Keygen-Version' => target_version,
    }

    # NOTE(ezekg) Legacy signatures are deprecated
    headers['X-Signature'] = sign_response_data(algorithm: :legacy, account: account, data: body) if
      account.created_at < SignatureHeaders::LEGACY_SIGNATURE_UNTIL

    res = Request.post(endpoint.url, {
      write_timeout: 15.seconds.to_i,
      read_timeout: 15.seconds.to_i,
      open_timeout: 15.seconds.to_i,
      headers:,
      body:,
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
        last_response_body: body,
        status: ACCEPTABLE_CODES.include?(res.code) ? 'DELIVERED' : 'FAILING',
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
        event.update!(status: 'FAILED')
        endpoint.disable!

        return
      in endpoint: /\.ngrok\.io/, last_response_code: 504
        Keygen.logger.warn "[webhook_worker] Skipping retries for bad ngrok endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        event.update!(status: 'FAILED')

        return
      in endpoint: /\.loca\.lt/, last_response_code: 504
        Keygen.logger.warn "[webhook_worker] Skipping retries for bad localtunnel endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        event.update!(status: 'FAILED')

        return
      in last_response_code: 410
        Keygen.logger.warn "[webhook_worker] Disabling Gone endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        # Automatically disable endpoints returning 410 Gone
        event.update!(status: 'FAILED')
        endpoint.disable!

        return
      in last_response_code: 530
        Keygen.logger.warn "[webhook_worker] Disabling Frozen endpoint: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=#{res.code}"

        # Automatically disable endpoints returning 530 Frozen
        event.update!(status: 'FAILED')
        endpoint.disable!

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
      last_response_body: 'SSL_ERROR',
      status: 'FAILING',
    )

    raise FailedRequestError
  rescue Net::WriteTimeout, # Our request to the endpoint timed out
         Net::ReadTimeout,
         Net::OpenTimeout
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=REQ_TIMEOUT"

    event.update!(
      last_response_code: nil,
      last_response_body: 'REQ_TIMEOUT',
      status: 'FAILING',
    )

    raise FailedRequestError
  rescue Errno::ECONNREFUSED # Stop sending requests when the connection is refused
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=CONN_REFUSED"

    event.update!(
      last_response_code: nil,
      last_response_body: 'CONN_REFUSED',
      status: 'FAILED',
    )
  rescue Errno::ECONNRESET # Stop sending requests when the connection is reset
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=CONN_RESET"

    event.update!(
      last_response_code: nil,
      last_response_body: 'CONN_RESET',
      status: 'FAILED',
    )
  rescue Errno::ENETUNREACH # Stop sending requests when the network is unreachable
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=NET_UNREACH"

    event.update!(
      last_response_code: nil,
      last_response_body: 'NET_UNREACH',
      status: 'FAILED',
    )
  rescue Errno::EHOSTUNREACH # Stop sending requests when the host is unreachable
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=HOST_UNREACH"

    event.update!(
      last_response_code: nil,
      last_response_body: 'HOST_UNREACH',
      status: 'FAILED',
    )
  rescue SocketError # Stop sending requests if DNS is no longer working for endpoint
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=DNS_ERROR"

    event.update!(
      last_response_code: nil,
      last_response_body: 'DNS_ERROR',
      status: 'FAILED',
    )
  rescue EOFError # Stop sending requests if endpoint is sending an EOF
    Keygen.logger.warn "[webhook_worker] Failed webhook event: type=#{event_type.event} account=#{account.id} event=#{event.id} endpoint=#{endpoint.id} url=#{endpoint.url} code=EOF_ERROR"

    event.update!(
      last_response_code: nil,
      last_response_body: 'EOF_ERROR',
      status: 'FAILED',
    )
  end

  class FailedRequestError < StandardError
    # Silence backtrace for failed webhooks (not needed, too noisy)
    def backtrace = nil
  end

  class Request
    include HTTParty
  end
end
