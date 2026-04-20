# frozen_string_literal: true

require 'rails_helper'
require 'spec_helper'

describe RequestLogger, type: :concern, only: :ee do
  controller_class = Class.new(ActionController::API) do
    include RequestLogger

    def internal_request? = false
  end

  let(:controller) { controller_class.new }
  let(:request)    { instance_double(ActionDispatch::Request) }
  let(:response)   { instance_double(ActionDispatch::Response) }

  before do
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:response).and_return(response)
  end

  describe '#request_log_request_body' do
    it 'returns nil when the request body is empty' do
      allow(request).to receive(:request_parameters).and_return({}.with_indifferent_access)

      expect(controller.send(:request_log_request_body)).to be_nil
    end

    it 'returns nil when the request body has no meta or data keys' do
      allow(request).to receive(:request_parameters).and_return({ 'foo' => 'bar' }.with_indifferent_access)

      expect(controller.send(:request_log_request_body)).to be_nil
    end

    it 'serializes meta and data keys to camel case' do
      allow(request).to receive(:request_parameters).and_return({
        'data' => {
          'type' => 'users',
          'attributes' => { 'first_name' => 'Jane' },
        },
        'meta' => { 'request_id' => 'abc' },
      }.with_indifferent_access)

      body   = controller.send(:request_log_request_body)
      parsed = JSON.parse(body)

      expect(parsed).to eq(
        'data' => {
          'type' => 'users',
          'attributes' => { 'firstName' => 'Jane' },
        },
        'meta' => { 'requestId' => 'abc' },
      )
    end

    it 'redacts sensitive values from request body' do
      allow(request).to receive(:request_parameters).and_return({
        'data' => {
          'type' => 'users',
          'attributes' => {
            'email'    => 'user@example.com',
            'password' => 'supersecretpassword',
            'token'    => 'abcdefghijklmnopqrstuvwxyz',
          },
        },
        'meta' => {
          'otp'    => '123456',
          'secret' => 'a-very-secret-value',
          'auth'   => { 'api_key' => 'topsecretapikey12345' },
        },
      }.with_indifferent_access)

      body   = controller.send(:request_log_request_body)
      parsed = JSON.parse(body)

      expect(parsed).to eq(
        'data' => {
          'type' => 'users',
          'attributes' => {
            'email'    => 'user@example.com',
            'password' => 's...d',
            'token'    => 'abcd...wxyz',
          },
        },
        'meta' => {
          'otp'    => '1...6',
          'secret' => 'a...e',
          'auth'   => { 'apiKey' => 'tops...2345' },
        },
      )
    end
  end

  describe '#request_log_response_body' do
    it 'returns nil when the response body is empty' do
      allow(response).to receive(:body).and_return('')

      expect(controller.send(:request_log_response_body)).to be_nil
    end

    it 'redacts sensitive values from response body' do
      allow(response).to receive(:content_type).and_return('application/vnd.api+json')
      allow(response).to receive(:body).and_return({
        'data' => {
          'type' => 'licenses',
          'attributes' => {
            'key'         => 'AAAA-BBBB-CCCC-DDDD-EEEE-FFFF',
            'certificate' => '-----BEGIN CERT-----abcdefghij-----END CERT-----',
            'email'       => 'user@example.com',
          },
        },
        'meta' => {
          'secret' => 'topsecretvalue123456',
        },
      }.to_json)

      result = controller.send(:request_log_response_body)
      parsed = JSON.parse(result)

      expect(parsed).to eq(
        'data' => {
          'type' => 'licenses',
          'attributes' => {
            'key'         => 'AAAA...FFFF',
            'certificate' => '----...----',
            'email'       => 'user@example.com',
          },
        },
        'meta' => {
          'secret' => 'tops...3456',
        },
      )
    end

    it 'returns raw text for text responses' do
      allow(response).to receive(:content_type).and_return('text/plain')
      allow(response).to receive(:body).and_return('hello world')

      expect(controller.send(:request_log_response_body)).to eq 'hello world'
    end

    it 'returns nil for binary responses' do
      allow(response).to receive(:content_type).and_return('application/octet-stream')
      allow(response).to receive(:body).and_return('binarydata')

      expect(controller.send(:request_log_response_body)).to be_nil
    end
  end

  describe '#log_request?' do
    let(:account) { build(:account) }
    let(:session) { build(:session, account:) }

    before do
      allow(request).to receive(:path_parameters).and_return(controller: 'api/v1/licenses')
    end

    after do
      Current.reset
    end

    it 'returns false when there is no account' do
      Current.account = nil

      expect(controller.send(:log_request?)).to be false
    end

    it 'returns true when there is an account' do
      Current.account = account

      expect(controller.send(:log_request?)).to be true
    end

    it 'returns true when there is no session' do
      Current.account = account
      Current.session = nil

      expect(controller.send(:log_request?)).to be true
    end

    it 'returns true when there is a session' do
      Current.account = account
      Current.session = session

      expect(controller.send(:log_request?)).to be true
    end

    it 'returns false for an ignored resource' do
      allow(request).to receive(:path_parameters).and_return(controller: 'api/v1/webhook_endpoints')

      expect(controller.send(:log_request?)).to be false
    end
  end

  describe '#request_log_origin' do
    it 'returns "api" for an external request' do
      allow(controller).to receive(:internal_request?).and_return(false)

      expect(controller.send(:request_log_origin)).to eq 'api'
    end

    it 'returns "ui" for an internal request' do
      allow(controller).to receive(:internal_request?).and_return(true)

      expect(controller.send(:request_log_origin)).to eq 'ui'
    end
  end
end
