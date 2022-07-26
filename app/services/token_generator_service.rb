# frozen_string_literal: true

class TokenGeneratorService < BaseService
  def initialize(account:, bearer:, expiry: nil, max_activations: nil, max_deactivations: nil, permissions: nil)
    raise ArgumentError, 'account is missing' if
      account.nil?

    raise ArgumentError, 'bearer is missing' if
      bearer.nil?

    @account           = account
    @bearer            = bearer
    @expiry            = expiry
    @permissions       = permissions
    @max_activations   = max_activations
    @max_deactivations = max_deactivations
  end

  def call
    kwargs = { max_activations:, max_deactivations:, permissions: }.reject { _2.nil? }
    token = account.tokens.create!(bearer:, expiry:, **kwargs)

    token.generate!

    token
  end

  private

  attr_reader :account,
              :bearer,
              :expiry,
              :max_activations,
              :max_deactivations,
              :permissions
end
