class TokenAuthenticationService < BaseService
  TOKEN_ID_REGEX = /\A([^\.]+)\.([^\.]+)/ # Form: {account}.{id}.xxx

  def initialize(account:, token:)
    @account = account
    @token   = token
  end

  def execute
    return nil unless account.present? && token.present?
    version = token[-2..-1] # TODO(ezekg) This can't handle token versions beyond v9 (2 chars)

    case version
    when "v1"
      matches = TOKEN_ID_REGEX.match token
      return nil unless matches.present? &&
                        "#{account.id}".delete("-") == matches[1]

      # FIXME(ezekg) Can't figure out a clean way to cache v1 tokens since we don't
      #              store the raw token value anywhere, which makes invalidation
      #              harder on revocation.
      tok = account.tokens.preload(bearer: [:role]).find_by id: matches[2]

      if tok&.compare_hashed_token(:digest, token, version: "v1")
        tok
      else
        nil
      end
    when "v2"
      digest = OpenSSL::HMAC.hexdigest "SHA512", account.private_key, token
      tok = Rails.cache.fetch(cache_key(digest), expires_in: 15.minutes) do
        account.tokens.find_by digest: digest
      end

      tok
    end
  end

  private

  attr_reader :account, :token

  def cache_key(t)
    Token.cache_key t
  end
end
