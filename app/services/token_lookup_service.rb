# frozen_string_literal: true

class TokenLookupService < BaseService
  TOKEN_LEGACY_RE = /\A(?<account_id>[^\.]+)\.(?<token_id>[^\.]+)\.(?<bits>.+?)(?<version>v\d+)\z/.freeze
  TOKEN_RE        = /\A(?<bits>.+?)\.(?<version>v\d+)\z/.freeze
  TOKEN_CACHE_TTL = 15.minutes

  def initialize(account:, token:, environment: nil)
    @account     = account
    @token       = token
    @environment = environment
  end

  def call
    return nil unless
      account.present? && token.present?

    case version
    when 'v1'
      matches = TOKEN_LEGACY_RE.match(token)
      return nil unless
        matches.present? && account.id.remove('-') == matches[:account_id]

      # FIXME(ezekg) Can't figure out a clean way to cache v1 tokens since we don't
      #              store the raw token value anywhere, which makes invalidation
      #              harder on revocation.
      tok = tokens.find_by(id: matches[:token_id])

      if tok&.compare_hashed_token(:digest, token, version: 'v1')
        tok
      else
        nil
      end
    when 'v2'
      digest = OpenSSL::HMAC.hexdigest('SHA512', account.private_key, token)

      tokens.find_by(digest:)
    when 'v3'
      digest = OpenSSL::HMAC.hexdigest('SHA256', account.secret_key, token)

      tokens.find_by(digest:)
    end
  end

  private

  attr_reader :environment,
              :account,
              :token

  def tokens  = account.tokens.for_environment(environment, strict: true)
  def version = token[-2..-1]&.downcase
end
