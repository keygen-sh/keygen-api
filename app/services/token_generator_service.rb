# frozen_string_literal: true

class TokenGeneratorService < BaseService
  def initialize(account:, bearer:, expiry: nil, name: nil, max_activations: nil, max_deactivations: nil, permissions: nil)
    raise ArgumentError, 'account is missing' if
      account.nil?

    raise ArgumentError, 'bearer is missing' if
      bearer.nil?

    @account           = account
    @bearer            = bearer
    @expiry            = expiry
    @name              = name
    @permissions       = permissions
    @max_activations   = max_activations
    @max_deactivations = max_deactivations
  end

  def call
    kwargs = { max_activations:, max_deactivations:, permissions: }.compact
    token = account.tokens.create!(bearer:, expiry:, name:, **kwargs)

    token.generate!

    token
  end

  private

  attr_reader :account,
              :bearer,
              :expiry,
              :name,
              :max_activations,
              :max_deactivations,
              :permissions
end
