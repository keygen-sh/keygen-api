require 'rails_helper'
require 'spec_helper'
require 'sidekiq/testing'

describe CreateWebhookEventService do

  def create_webhook_event!
    CreateWebhookEventService.new(
      event: 'license.created',
      account: @account,
      resource: @resource
    ).execute

    @account.webhook_events.last
  end

  def jsonapi_render(model)
    JSONAPI::Serializable::Renderer.new.render(model, {
      expose: { url_helpers: Rails.application.routes.url_helpers },
      class: {
        Account: SerializableAccount,
        Token: SerializableToken,
        Product: SerializableProduct,
        Policy: SerializablePolicy,
        User: SerializableUser,
        Role: SerializableRole,
        License: SerializableLicense,
        Machine: SerializableMachine,
        Key: SerializableKey,
        Billing: SerializableBilling,
        Plan: SerializablePlan,
        WebhookEndpoint: SerializableWebhookEndpoint,
        WebhookEvent: SerializableWebhookEvent,
        Metric: SerializableMetric,
        Error: SerializableError
      }
    }).to_json
  end

  before do
    Sidekiq::Testing.inline!

    @account = create :account
    @endpoint = create :webhook_endpoint, account: @account
    @resource = create :license, account: @account

    # FIXME(ezekg) Instantiate a webhook event so Active Record lazy loads the model's
    #              attributes otherwise the mocks below will fail
    WebhookEvent.new

    # Make sure our license resources always have the same timestamps so comparison is easier
    allow_any_instance_of(WebhookEvent).to receive(:updated_at).and_return Time.current
    allow_any_instance_of(WebhookEvent).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:created_at).and_return Time.current
    allow_any_instance_of(License).to receive(:updated_at).and_return Time.current

    # FIXME(ezekg) Workaround for sidekiq-status for not having good test support
    allow_any_instance_of(WebhookEvent).to receive(:status).and_return 'working'
  end

  after do
    Sidekiq::Worker.clear_all
  end

  it 'should create a new webhook event' do
    event = create_webhook_event!

    expect(event).to be_a WebhookEvent
  end

  it 'the event should contain the correct event type' do
    event = create_webhook_event!

    expect(event.event).to eq 'license.created'
  end

  it 'the event should contain the correct endpoint' do
    event = create_webhook_event!

    expect(event.endpoint).to eq @endpoint.url
  end

  it 'the event payload should contain a snapshot of the resource' do
    payload = jsonapi_render @resource
    event = create_webhook_event!

    expect(event.payload).to eq payload
  end

  it 'the event should contain the last response code' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204)
    }

    event = create_webhook_event!

    expect(event.last_response_code).to eq 204
  end

  it 'the event should contain the last response body' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 200, body: 'OK')
    }

    event = create_webhook_event!

    expect(event.last_response_body).to eq 'OK'
  end

  it 'should attempt to deliver the event' do
    allow(WebhookWorker::Request).to receive(:post) { |url, opts|
      OpenStruct.new(url: url, code: 200, **opts)
    }

    event = create_webhook_event!
    body = jsonapi_render event
    url = @endpoint.url

    expect(WebhookWorker::Request).to have_received(:post).with(
      url,
      hash_including(body: body)
    )
  end

  it 'should succeed when event delivery is ok' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 204)
    }

    expect { create_webhook_event! }.to_not raise_error
  end

  it 'should retry when event delivery fails' do
    allow(WebhookWorker::Request).to receive(:post) {
      OpenStruct.new(code: 500)
    }

    expect { create_webhook_event! }.to raise_error WebhookWorker::FailedRequestError
  end
end