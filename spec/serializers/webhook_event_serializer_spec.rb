# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe WebhookEventSerializer do
  let(:account) { create(:account) }
  let(:token)   { "admin-#{'a1' * 32}v3" }
  let(:payload) {
    {
      data: {
        type: 'users',
        id: SecureRandom.uuid,
        attributes: { email: 'user@example.com', note: token },
        relationships: { account: { data: { type: 'accounts', id: account.id } } },
      },
      included: [
        { type: 'second-factors', attributes: { uri: 'otpauth://totp/Keygen?secret=JBSWY3DPEHPK3PXP&issuer=Keygen' } },
      ],
      meta: { passwordResetToken: 'abcdefghijklmnopqrstuvwxyz' },
    }.to_json
  }

  let(:webhook_event) { create(:webhook_event, account:, payload:) }

  def render(resource, **)
    renderer = Keygen::JSONAPI::Renderer.new(account:, **)
    rendered = renderer.render(resource)

    rendered.dig(:data, :attributes, :payload)
  end

  context 'when rendering for a webhook' do
    it 'renders the payload verbatim' do
      expect(render(webhook_event, context: :webhook)).to eq payload
    end
  end

  context 'when not rendering for a webhook' do
    it 'filters sensitive keys and values from the payload' do
      filtered = JSON.parse(render(webhook_event))

      expect(filtered).to eq(
        'data' => {
          'type' => 'users',
          'id' => JSON.parse(payload).dig('data', 'id'),
          'attributes' => { 'email' => 'user@example.com', 'note' => 'admi...a1v3' },
          'relationships' => { 'account' => { 'data' => { 'type' => 'accounts', 'id' => account.id } } },
        },
        'included' => [
          { 'type' => 'second-factors', 'attributes' => { 'uri' => 'otpa...ygen' } },
        ],
        'meta' => { 'passwordResetToken' => 'abcd...wxyz' },
      )
    end

    it 'does not modify a non-sensitive payload' do
      webhook_event.update!(payload: '{"data":{"type":"licenses","attributes":{"name":"foo","uses":1,"suspended":false,"expiry":null}}}')

      expect(render(webhook_event)).to eq webhook_event.payload
    end

    it 'renders a nil payload' do
      webhook_event.update!(payload: nil)

      expect(render(webhook_event)).to be_nil
    end
  end

  describe RetryWebhookEventService do
    it 'delivers the payload verbatim' do
      new_event = RetryWebhookEventService.call(event: webhook_event)

      expect(new_event.payload).to eq payload
      expect(WebhookWorker.jobs.size).to eq 1

      *, data = WebhookWorker.jobs.last['args']

      expect(JSON.parse(data).dig('data', 'attributes', 'payload')).to eq payload
    end
  end
end
