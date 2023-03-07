# frozen_string_literal: true

class TokenGeneratorService < BaseService
  def initialize(account:, bearer:, **options)
    raise ArgumentError, 'account is missing' if
      account.nil?

    raise ArgumentError, 'bearer is missing' if
      bearer.nil?

    @account = account
    @bearer  = bearer
    @options = options
  end

  def call
    token = account.tokens.create!(bearer:, **options)

    token.generate!

    token
  end

  private

  attr_reader :account,
              :bearer,
              :options
end
