# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe BroadcastEventService do
  let(:account) { create(:account) }
  let(:endpoint) { create(:webhook_endpoint, account: account) }
  let(:resource) { create(:license, account: account) }

  def create_webhook_event!(account, resource, event: 'license.created')
    throw if endpoint.nil?

    BroadcastEventService.call(
      account:,
      resource:,
      event:,
    )

    event = account.webhook_events.last

    event
  end

  def create_validation_webhook_event!(account, resource, meta)
    throw if endpoint.nil?

    BroadcastEventService.call(
      event: 'license.validation.succeeded',
      account:,
      resource:,
      meta:,
    )

    event = account.webhook_events.last

    event
  end

  def jsonapi_render(resource, account:, meta: nil, **options)
    Keygen::JSONAPI::Renderer.new(account:, context: :webhook, **options)
                             .render(resource, **{ meta: }.compact)
                             .to_json
  end

  before { Sidekiq::Testing.inline! }
  after  { Sidekiq::Testing.fake! }

  before do
    # FIXME(ezekg) Instantiate models so Active Record lazy loads the model's
    #              attributes otherwise the mocks below will fail
    WebhookEvent.new
    License.new

    # Make sure our license resources always have the same timestamps so comparison is easier
    allow_any_instance_of(WebhookEvent).to receive(:updated_at).and_return Time.current
    allow_any_instance_of(WebhookEvent).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:updated_at).and_return Time.current

    # FIXME(ezekg) Mock HTTPParty so we don't actually make any real requests
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204, body: nil)
    }
  end

  it 'should create a new webhook event' do
    event = create_webhook_event!(account, resource)

    expect(event).to be_a WebhookEvent
  end

  it 'the event should contain the correct event type' do
    event = create_webhook_event!(account, resource)
    type = event.event_type

    expect(type.event).to eq 'license.created'
  end

  it 'the event should contain the correct endpoint' do
    event = create_webhook_event!(account, resource)

    expect(event.endpoint).to eq endpoint.url
  end

  it 'the event payload should contain a snapshot of the resource' do
    payload = jsonapi_render(resource, account:)
    event = create_webhook_event!(account, resource)

    expect(event.payload).to eq payload
  end

  it 'the event payload should contain a snapshot of the resource meta' do
    meta = {
      ts: Time.current,
      valid: false,
      detail: 'is expired',
      constant: 'EXPIRED',
    }

    payload = jsonapi_render(resource, account:, meta:)
    event = create_validation_webhook_event!(account, resource, meta)

    expect(event.payload).to eq payload
  end

  it 'the event should contain the last response code' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204, body: nil)
    }

    event = create_webhook_event!(account, resource)

    expect(event.last_response_code).to eq 204
  end

  it 'the event should contain the last response body' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 200, body: 'OK')
    }

    event = create_webhook_event!(account, resource)

    expect(event.last_response_body).to eq 'OK'
  end

  it 'the event should not store large response bodies' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 200, body: SecureRandom.hex(8092))
    }

    event = create_webhook_event!(account, resource)

    expect(event.last_response_body).to eq 'RES_BODY_TOO_LARGE'
  end

  it 'should attempt to deliver the event' do
    allow_any_instance_of(WebhookEvent).to receive(:last_response_code).and_return 200
    allow_any_instance_of(WebhookEvent).to receive(:last_response_body).and_return 'OK'
    allow_any_instance_of(WebhookEvent).to receive(:status).and_return 'DELIVERED'
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 200, body: 'OK')
    }

    event = create_webhook_event!(account, resource)
    body  = jsonapi_render(event, account:)
    url   = endpoint.url

    expect(WebhookWorker::Request).to have_received(:post).with(
      url,
      hash_including(body:),
    )
  end

  it 'should succeed when event delivery is ok' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204, body: nil)
    }

    expect { create_webhook_event!(account, resource) }.to_not raise_error
  end

  it 'should raise when event delivery fails' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 500, body: nil)
    }

    expect { create_webhook_event!(account, resource) }.to raise_error WebhookWorker::FailedRequestError
  end

  it 'should raise when event delivery fails due to SSL error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise OpenSSL::SSL::SSLError.new
    }

    expect { create_webhook_event!(account, resource) }.to raise_error WebhookWorker::FailedRequestError
    event = WebhookEvent.last

    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'SSL_ERROR'
  end

  it 'should raise when event delivery fails due to read timeout error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Net::ReadTimeout.new
    }

    expect { create_webhook_event!(account, resource) }.to raise_error WebhookWorker::FailedRequestError
    event = WebhookEvent.last

    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'REQ_TIMEOUT'
  end

  it 'should raise when event delivery fails due to open timeout error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Net::OpenTimeout.new
    }

    expect { create_webhook_event!(account, resource) }.to raise_error WebhookWorker::FailedRequestError
    event = WebhookEvent.last

    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'REQ_TIMEOUT'
  end

  it 'should skip when event delivery fails due to DNS error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise SocketError.new
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'DNS_ERROR'
  end

  it 'should skip when event delivery fails due to connection refused error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Errno::ECONNREFUSED.new
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'CONN_REFUSED'
  end

  it 'should not skip when event delivery fails due to an exception' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Exception.new
    }

    expect { create_webhook_event!(account, resource) }.to raise_error Exception
  end

  it 'should disable endpoint when status is 410 Gone' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 410, body: '410 Gone')
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
    expect(event).to_not be_nil
    expect(event.last_response_body).to eq '410 Gone'
    expect(event.last_response_code).to eq 410

    expect { endpoint.reload }.to_not raise_error
    expect(endpoint.subscriptions).to be_empty
  end

  context 'when endpoint has an environment' do
    before do
      create_list(:webhook_endpoint, 5, :in_isolated_environment, account:)
      create_list(:webhook_endpoint, 2, :in_shared_environment, account:)
      create_list(:webhook_endpoint, 3, :in_nil_environment, account:)
    end

    within_environment :isolated do
      it 'should send to the isolated environment' do
        expect { BroadcastEventService.call(account:, resource:, event: 'machine.created') }.to(
          change { WebhookEvent.count }.by(5),
        )
      end
    end

    within_environment :shared do
      it 'should send to the shared environment' do
        expect { BroadcastEventService.call(account:, resource:, event: 'machine.created') }.to(
          change { WebhookEvent.count }.by(2),
        )
      end
    end

    within_environment nil do
      it 'should send to the nil environment' do
        expect { BroadcastEventService.call(account:, resource:, event: 'machine.created') }.to(
          change { WebhookEvent.count }.by(3),
        )
      end
    end
  end

  context 'when an ngrok tunnel is used' do
    let(:endpoint) { create(:webhook_endpoint, url: 'https://keygen.ngrok.io/webhooks', account: account) }

    it 'should disable when endpoint is an invalid tunnel' do
      allow(WebhookWorker::Request).to receive(:post) {
        OpenStruct.new(code: 404, body: 'Tunnel foo.ngrok.io not found')
      }

      event = nil
      expect { event = create_webhook_event!(account, resource) }.to_not raise_error
      expect(event).to_not be_nil
      expect(event.last_response_body).to eq 'Tunnel foo.ngrok.io not found'
      expect(event.last_response_code).to eq 404

      expect { endpoint.reload }.to_not raise_error
      expect(endpoint.subscriptions).to be_empty
    end

    it 'should not retry when endpoint is an unreachable tunnel' do
      allow(WebhookWorker::Request).to receive(:post) {
        OpenStruct.new(code: 504, body: '')
      }

      event = nil
      expect { event = create_webhook_event!(account, resource) }.to_not raise_error
      expect(event).to_not be_nil
      expect(event.last_response_code).to eq 504
      expect(event.last_response_body).to eq ''

      expect { endpoint.reload }.to_not raise_error
      expect(endpoint.subscriptions).to_not be_empty
    end
  end

  context 'when serializing resources with sensitive secrets' do
    it 'the account payload should not contain private keys' do
      resource = create(:account)

      event = create_webhook_event!(account, resource, event: 'test.account.created')
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')
      meta = payload.fetch('meta', {})

      expect(attrs.key?('privateKeys')).to eq false
      expect(attrs.key?('privateKey')).to eq false

      expect(meta.key?('privateKeys')).to eq false
      expect(meta.key?('privateKey')).to eq false
    end

    it 'the token payload should not contain one-time secret token' do
      resource = create(:token, account: account)

      event = create_webhook_event!(account, resource, event: 'token.created')
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('token')).to eq false
    end

    it 'the second factor payload should not contain one-time secret uri' do
      resource = create(:second_factor, account: account)

      event = create_webhook_event!(account, resource, event: 'second-factor.created')
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('uri')).to eq false
    end

    it 'the user payload should not contain password' do
      resource = create(:user, account: account)

      event = create_webhook_event!(account, resource, event: 'user.created')
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('password')).to eq false
    end
  end

  context 'when signature algorithm is ed25519' do
    let(:endpoint) { create(:webhook_endpoint, url: 'https://webhooks.keygen.example', signature_algorithm: 'ed25519', account: account) }

    it 'should have a valid legacy signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body = options.fetch(:body)

        ok = SignatureHelper.verify_legacy(account: account, signature: headers['X-Signature'], body: body)
        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end

    it 'should have a valid signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body    = options.fetch(:body)
        uri     = URI.parse(endpoint.url)

        ok = SignatureHelper.verify(
          account: account,
          method: 'POST',
          host: uri.host,
          uri: uri.path,
          body: body,
          signature_algorithm: 'ed25519',
          signature_header: headers['Keygen-Signature'],
          digest_header: headers['Digest'],
          date_header: headers['Date'],
        )

        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end
  end

  context 'when signature algorithm is rsa-pss-sha256' do
    let(:endpoint) { create(:webhook_endpoint, url: 'https://keygen.example/webhooks', signature_algorithm: 'rsa-pss-sha256', account: account) }

    it 'should have a valid legacy signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body = options.fetch(:body)

        ok = SignatureHelper.verify_legacy(account: account, signature: headers['X-Signature'], body: body)
        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end

    it 'should have a valid signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body    = options.fetch(:body)
        uri     = URI.parse(endpoint.url)

        ok = SignatureHelper.verify(
          account: account,
          method: 'POST',
          host: uri.host,
          uri: uri.path,
          body: body,
          signature_algorithm: 'rsa-pss-sha256',
          signature_header: headers['Keygen-Signature'],
          digest_header: headers['Digest'],
          date_header: headers['Date'],
        )

        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end
  end

  context 'when signature algorithm is rsa-sha256' do
    let(:endpoint) { create(:webhook_endpoint, url: "https://keygen.example/hooks?token=#{SecureRandom.hex}", signature_algorithm: 'rsa-sha256', account: account) }

    it 'should have a valid legacy signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body = options.fetch(:body)

        ok = SignatureHelper.verify_legacy(account: account, signature: headers['X-Signature'], body: body)
        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end

    it 'should have a valid signature header' do
      allow(WebhookWorker::Request).to receive(:post) { |url, options|
        headers = options.fetch(:headers)
        body    = options.fetch(:body)
        uri     = URI.parse(endpoint.url)

        ok = SignatureHelper.verify(
          account: account,
          method: 'POST',
          host: uri.host,
          uri: "#{uri.path}?#{uri.query}",
          body: body,
          signature_algorithm: 'rsa-sha256',
          signature_header: headers['Keygen-Signature'],
          digest_header: headers['Digest'],
          date_header: headers['Date'],
        )

        expect(ok).to eq true

        OpenStruct.new(code: 200, body: '')
      }

      create_webhook_event!(account, resource)
    end
  end

  context 'when endpoint version is greater than account version' do
    let(:account)  { create(:account, api_version: '1.0') }
    let(:endpoint) { create(:webhook_endpoint, api_version: CURRENT_API_VERSION, account:) }
    let(:resource) { create(:policy, account:) }

    it 'should migrate the webhook event payload' do
      expected = jsonapi_render(resource, account:, api_version: endpoint.api_version)

      allow(WebhookWorker::Request).to(
        receive(:post) do |url, options|
          options => headers:, body:

          api_version = headers['Keygen-Version']
          payload     = JSON.parse(body, symbolize_names: true)
                            .dig(
                              :data,
                              :attributes,
                              :payload,
                            )

          expect(api_version).to eq CURRENT_API_VERSION
          expect(payload).to eq expected

          OpenStruct.new(
            code: 204,
            body: '',
          )
        end
      )

      event = create_webhook_event!(account, resource,
        event: 'policy.created',
      )

      expect(event.api_version).to eq CURRENT_API_VERSION
      expect(event.payload).to eq expected
    end
  end

  context 'when endpoint version is less than account version' do
    let(:account)  { create(:account, api_version: CURRENT_API_VERSION) }
    let(:endpoint) { create(:webhook_endpoint, api_version: '1.0', account:) }
    let(:resource) { create(:policy, account:) }

    it 'should migrate the webhook event payload' do
      expected = jsonapi_render(resource, account:, api_version: endpoint.api_version)

      allow(WebhookWorker::Request).to(
        receive(:post) do |url, options|
          options => headers:, body:

          api_version = headers['Keygen-Version']
          payload     = JSON.parse(body, symbolize_names: true)
                            .dig(
                              :data,
                              :attributes,
                              :payload,
                            )

          expect(api_version).to eq '1.0'
          expect(payload).to eq expected

          OpenStruct.new(
            code: 204,
            body: '',
          )
        end
      )

      event = create_webhook_event!(account, resource,
        event: 'policy.created',
      )

      expect(event.api_version).to eq '1.0'
      expect(event.payload).to eq expected
    end
  end
end
