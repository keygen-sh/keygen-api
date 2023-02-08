# frozen_string_literal: true

class ResolveEnvironmentService < BaseService
  ENVIRONMENT_SCOPE_CACHE_TTL = 15.minutes

  def initialize(environment:, account:)
    @environment = environment
    @account     = account
  end

  def call
    return unless
      Keygen.ee?

    with_cache do
      FindByAliasService.call(account.environments, id: environment, aliases: %i[code])
    rescue Keygen::Error::NotFoundError
      raise Keygen::Error::InvalidEnvironmentError, 'environment is invalid'
    end
  end

  private

  attr_reader :environment,
              :account

  def cache = Rails.cache

  def with_cache
    key = Environment.cache_key(environment, account:)

    cache.fetch(key, skip_nil: true, expires_in: ENVIRONMENT_SCOPE_CACHE_TTL) do
      yield
    end
  end
end
