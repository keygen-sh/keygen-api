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

    cache(environment) do
      FindByAliasService.call(
        account.environments,
        aliases: %i[code],
        id: environment,
      )
    end
  end

  private

  attr_reader :environment,
              :account

  def cache(environment)
    key = Environment.cache_key(environment, account:)

    Rails.cache.fetch(key, skip_nil: true, expires_in: ENVIRONMENT_SCOPE_CACHE_TTL) do
      yield
    rescue Keygen::Error::NotFoundError
      raise Keygen::Error::InvalidEnvironmentError, 'environment is invalid'
    end
  end
end
