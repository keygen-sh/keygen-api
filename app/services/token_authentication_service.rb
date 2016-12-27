class TokenAuthenticationService < BaseService
  TOKEN_ID_REGEX = /\A([^\.]+)\.([^\.]+)/ # Form: {account}.{id}.xxx

  def initialize(account:, token:)
    @account = account
    @token   = token
  end

  def execute
    token =~ TOKEN_ID_REGEX # Run regex against token

    return nil unless account&.id.delete("-") == $1

    tok = account.tokens.find_by id: $2

    if tok&.compare_encrypted_token(:digest, token)
      tok
    else
      nil
    end
  end

  private

  attr_reader :account, :token
end
