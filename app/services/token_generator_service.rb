class TokenGeneratorService < BaseService

  def initialize(account:, bearer:)
    @account = account
    @bearer  = bearer
  end

  def execute
    return nil if account.nil? || bearer.nil?

    token = bearer.tokens.create account: account
    token.generate!

    begin
      TokenCleanupWorker.perform_at(
        Token::TOKEN_DURATION,
        token.id
      )
    rescue Redis::CannotConnectError
      # noop
    end

    token
  end

  private

  attr_reader :account, :bearer
end
