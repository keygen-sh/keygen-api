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

    token
  end

  private

  attr_reader :account, :bearer, :expiry
end
