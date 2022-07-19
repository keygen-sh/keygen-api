# frozen_string_literal: true

class TokenGeneratorService < BaseService
  def initialize(account:, bearer:, expiry: nil, max_activations: nil, max_deactivations: nil)
    raise ArgumentError, 'account is missing' if
      account.nil?

    raise ArgumentError, 'bearer is missing' if
      bearer.nil?

    @account           = account
    @bearer            = bearer
    @expiry            = expiry
    @max_activations   = max_activations
    @max_deactivations = max_deactivations
  end

  def call
    token = bearer.tokens.create!(
      account: account,
      expiry: expiry,
      max_activations: max_activations,
      max_deactivations: max_deactivations,
    )

    token.generate!

    token
  end

  private

  attr_reader :account, :bearer, :expiry, :max_activations, :max_deactivations
end
