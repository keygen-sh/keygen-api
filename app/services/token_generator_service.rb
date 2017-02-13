class TokenGeneratorService < BaseService

  def initialize(account:, bearer:, expiry: nil)
    @account = account
    @bearer  = bearer
    @expiry  = expiry
  end

  def execute
    return nil if account.nil? || bearer.nil?

    opts = if !expiry.nil?
             { expiry: expiry }
           else
             {}
           end

    token = bearer.tokens.create account: account
    token.generate! **opts

    begin
      if expiry != false
        TokenCleanupWorker.perform_at(
          Token::TOKEN_DURATION,
          token.id
        )
      end
    rescue Redis::CannotConnectError
      # noop
    end

    token
  end

  private

  attr_reader :account, :bearer, :expiry
end
