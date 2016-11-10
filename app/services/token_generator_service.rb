class TokenGeneratorService < BaseService

  def initialize(account:, bearer:)
    @account = account
    @bearer  = bearer
  end

  def execute
    return nil if account.nil? || bearer.nil?

    token = bearer.tokens.create account: account
    token&.generate!

    token
  end

  private

  attr_reader :account, :bearer
end
