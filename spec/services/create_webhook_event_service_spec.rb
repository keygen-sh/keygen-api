# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'
require 'database_cleaner'
require 'sidekiq/testing'

DatabaseCleaner.strategy = :truncation, { except: ['event_types'] }

describe CreateWebhookEventService do
  let(:account) { create(:account) }
  let(:endpoint) { create(:webhook_endpoint, account: account) }
  let(:resource) { create(:license, account: account) }

  def create_webhook_event!(account, resource)
    throw if endpoint.nil?

    CreateWebhookEventService.new(
      event: 'license.created',
      account: account,
      resource: resource
    ).execute

    event = account.webhook_events.last

    event
  end

  def create_validation_webhook_event!(account, resource, meta)
    throw if endpoint.nil?

    CreateWebhookEventService.new(
      event: 'license.validation.succeeded',
      account: account,
      resource: resource,
      meta: meta
    ).execute

    event = account.webhook_events.last

    event
  end

  def jsonapi_render(model, options = nil)
    opts = {
      expose: { url_helpers: Rails.application.routes.url_helpers },
      class: {
        Account: SerializableAccount,
        Token: SerializableToken,
        Product: SerializableProduct,
        Policy: SerializablePolicy,
        User: SerializableUser,
        License: SerializableLicense,
        Machine: SerializableMachine,
        Key: SerializableKey,
        Billing: SerializableBilling,
        Plan: SerializablePlan,
        WebhookEndpoint: SerializableWebhookEndpoint,
        WebhookEvent: SerializableWebhookEvent,
        Metric: SerializableMetric,
        SecondFactor: SerializableSecondFactor,
        LicenseEntitlement: SerializableLicenseEntitlement,
        PolicyEntitlement: SerializablePolicyEntitlement,
        Entitlement: SerializableEntitlement,
        Error: SerializableError
      }
    }

    opts.merge! options unless options.nil?

    JSONAPI::Serializable::Renderer.new.render(model, opts).to_json
  end

  before do
    Sidekiq::Testing.inline!

    # FIXME(ezekg) Instantiate models so Active Record lazy loads the model's
    #              attributes otherwise the mocks below will fail
    WebhookEvent.new
    License.new

    # Make sure our license resources always have the same timestamps so comparison is easier
    allow_any_instance_of(WebhookEvent).to receive(:updated_at).and_return Time.current
    allow_any_instance_of(WebhookEvent).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:updated_at).and_return Time.current

    # FIXME(ezekg) Workaround for sidekiq-status for not having good test support
    allow_any_instance_of(WebhookEvent).to receive(:status).and_return 'working'

    # FIXME(ezekg) Mock HTTPParty so we don't actually make any real requests
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204, body: nil)
    }
  end

  after do
    Sidekiq::Worker.clear_all
    DatabaseCleaner.clean
    Rails.cache.clear
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
    payload = jsonapi_render(resource)
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

    payload = jsonapi_render(resource, meta: meta)
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
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 200, body: 'OK')
    }

    event = create_webhook_event!(account, resource)
    body = jsonapi_render(event)
    url = endpoint.url

    expect(WebhookWorker::Request).to have_received(:post).with(
      url,
      hash_including(body: body)
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

  it 'should skip when event delivery fails due to SSL error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise OpenSSL::SSL::SSLError.new
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'SSL_ERROR'
  end

  it 'should skip when event delivery fails due to read timeout error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Net::ReadTimeout.new
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
    expect(event).to_not be_nil
    expect(event.last_response_body).to eq 'REQ_TIMEOUT'
  end

  it 'should skip when event delivery fails due to open timeout error' do
    allow(WebhookWorker::Request).to receive(:post) {
      raise Net::OpenTimeout.new
    }

    event = nil
    expect { event = create_webhook_event!(account, resource) }.to_not raise_error
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

      event = create_webhook_event!(account, resource)
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

      event = create_webhook_event!(account, resource)
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('token')).to eq false
    end

    it 'the second factor payload should not contain one-time secret uri' do
      resource = create(:second_factor, account: account)

      event = create_webhook_event!(account, resource)
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('uri')).to eq false
    end

    it 'the user payload should not contain password' do
      resource = create(:user, account: account)

      event = create_webhook_event!(account, resource)
      payload = JSON.parse(event.payload)
      attrs = payload.dig('data', 'attributes')

      expect(attrs.key?('password')).to eq false
    end
  end
end