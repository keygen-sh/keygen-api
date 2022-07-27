# frozen_string_literal: true

class AuthorizationContext
  attr_reader :account,
              :bearer,
              :token

  def initialize(account:, bearer:, token:)
    @account = account
    @bearer  = bearer
    @token   = token
  end
end
