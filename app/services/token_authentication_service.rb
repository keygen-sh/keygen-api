class TokenAuthenticationService < BaseService
  TOKEN_ID_REGEX = /\A([^\.]+)\.([^\.]+)/ # Form: {account}.{bearer}.xxx

  def initialize(account:, token:)
    @account = account
    @token   = token
  end

  def execute
    token =~ TOKEN_ID_REGEX # Run regex against token

    return nil unless account&.hashid == $1

    tok = account.tokens.find_by_hashid $2

    if tok&.compare_encrypted_token(:digest, token)
      tok.bearer
    else
      nil
    end
  end

  private

  attr_reader :account, :token
end
