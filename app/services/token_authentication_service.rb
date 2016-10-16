class TokenAuthenticationService
  TOKEN_ID_REGEX = /\A([^_]+)/

  def initialize(account:, token:)
    @account = account
    @token   = token
  end

  def authenticate
    return nil unless account

    token =~ TOKEN_ID_REGEX
    tok = account.tokens.find_by_hashid $1

    if tok&.compare_encrypted_token(:digest, token)
      tok.bearer
    else
      nil
    end
  end

  private

  attr_reader :account, :token
end
