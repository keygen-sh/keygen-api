# frozen_string_literal: true

class TokenLookupService < BaseService
  TOKEN_VERSION_RE = /\A.+?(?<token_version>v\d+)\z/.freeze
  TOKEN_LEGACY_RE  = /\A(?<account_id>[^\.]+)\.(?<token_id>[^\.]+)\.(?<token_bits>.+?)(?<token_version>v\d+)\z/.freeze
  TOKEN_RE         = /\A(?<token_prefix>.+?)-(?<token_bits>.+?)(?<token_version>v\d+)\z/.freeze
  TOKEN_CACHE_TTL  = 15.minutes

  def initialize(account:, token:, environment: nil)
    @account     = account
    @token       = token
    @environment = environment
  end

  def call
    return nil unless
      account.present? && token.present?

    matches = TOKEN_VERSION_RE.match(token)
    return nil unless
      matches.present?

    case matches[:token_version]
    when 'v1'
      m = TOKEN_LEGACY_RE.match(token)
      return nil unless
        m.present? && account.id.remove('-') == m[:account_id]

      # FIXME(ezekg) Can't figure out a clean way to cache v1 tokens since we don't
      #              store the raw token value anywhere, which makes invalidation
      #              harder on revocation.
      instance = tokens.find_by(id: m[:token_id])

      if instance&.compare_hashed_token(:digest, token, version: 'v1')
        Keygen.logger.warn { "[token-lookup-service] v1 tokens are deprecated and must be regenerated: bearer_type=#{instance.bearer.class.name.inspect} bearer_id=#{instance.bearer.id.inspect} token_id=#{instance.id.inspect}" }

        # FIXME(ezekg) jit rehash token: https://github.com/bcrypt-ruby/bcrypt-ruby/pull/168
        digest = BCrypt::Engine.hash_secret(
          Digest::SHA256.hexdigest(token),
          BCrypt::Password.new(instance.digest).salt, # reuse salt
        )
        unless instance.send(:secure_compare, digest, instance.digest)
          Keygen.logger.warn { "[token-lookup-service] rehashing token: token_id=#{instance.id.inspect}" }

          instance.update!(digest:)
        end

        instance
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

  # NOTE(ezekg) When we're in the global (nil) environment, we want to enable strict mode
  #             so that we can't authenticate with a token from another environment,
  #             even if we have access to that environment's tokens.
  def tokens = account.tokens.for_environment(environment)
end
