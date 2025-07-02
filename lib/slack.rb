# frozen_string_literal: true

require 'httparty'

module Slack
  class Error < StandardError; end
  class SignatureError < Error; end
  class RequestError < Error; end

  class Client
    include HTTParty

    base_uri 'https://slack.com/api'

    def initialize(token:)
      @default_options = {
        headers: { authorization: "Bearer #{token}" },
      }
    end

    def create_channel(name:)
      res = post('/conversations.create',
        default_options.merge(query: { name: }),
      )

      res['channel']['id']
    end

    def share_channel(channel_id:, email:)
      res = post('/conversations.inviteShared',
        default_options.merge(query: {
          channel: channel_id,
          emails: email,
          external_limited: false, # allow them to invite teammates
        }),
      )

      res['invite_id']
    end

    private

    attr_reader :default_options

    def post(...)
      res = self.class.post(...)
      raise RequestError.new(res['error']) unless res['ok']
      res
    end
  end

  module Event
    MAX_AGE = 5.minutes

    extend self

    def verify_signature!(request, signing_secret:)
      raise SignatureError, 'signing secret is required' unless signing_secret.present?

      verifier = Verifier.new(request, signing_secret:)

      raise SignatureError, 'signature is expired' if     verifier.expired?
      raise SignatureError, 'signature is invalid' unless verifier.ok?
    end

    private

    # https://api.slack.com/authentication/verifying-requests-from-slack
    class Verifier
      def initialize(request, signing_secret:)
        @request        = request
        @signing_secret = signing_secret
      end

      def expired? = timestamp.nil? || (Time.current.to_i - timestamp.to_i).abs > MAX_AGE
      def ok?
        digest    = OpenSSL::Digest::SHA256.new
        hexdigest = OpenSSL::HMAC.hexdigest(digest, signing_secret, signing_data)
        sig       = "#{version}=#{hexdigest}"

        Rack::Utils.secure_compare(sig, signature)
      end

      private

      attr_reader :request, :signing_secret

      def signing_data = [version, timestamp, body].join(':')

      def timestamp = @timestamp ||= request.headers['X-Slack-Request-Timestamp']
      def signature = @signature ||= request.headers['X-Slack-Signature']
      def version   = 'v0'

      def body = @body ||= begin
        input = request.body
        input.rewind
        body = input.read
        input.rewind
        body
      end
    end
  end
end
