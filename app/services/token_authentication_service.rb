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
      token =~ TOKEN_ID_REGEX # Run regex against token
      return nil unless account.id.delete("-") == $1

      tok = account.tokens.find_by id: $2

      if tok&.compare_hashed_token(:digest, token, version: "v1")
        tok
      else
        nil
      end
    when "v2"
      hmac = OpenSSL::HMAC.hexdigest "SHA512", account.private_key, token
      tok = account.tokens.find_by digest: hmac

      tok
    end
  end

  private

  attr_reader :account, :token
end
