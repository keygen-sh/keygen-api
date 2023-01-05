# frozen_string_literal: true

class ResolveEnvironmentService < BaseService
  ENVIRONMENT_SCOPE_HEADER_KEY = 'Keygen-Environment'.freeze
  ENVIRONMENT_SCOPE_CACHE_TTL  = 15.minutes

  def initialize(account:, request:)
    @account = account
    @request = request
  end

  def call
    id = request.headers[ENVIRONMENT_SCOPE_HEADER_KEY]
    return unless
      id.present?

    cache(id) do
      FindByAliasService.call(
        account.environments,
        aliases: %i[code],
        id:,
      )
    end
  end

  private

  attr_reader :account,
              :request

  def cache(env_id)
    key = Environment.cache_key(env_id, account:)

    Rails.cache.fetch(key, skip_nil: true, expires_in: ENVIRONMENT_SCOPE_CACHE_TTL) do
      yield
    rescue Keygen::Error::NotFoundError
      raise Keygen::Error::InvalidEnvironmentError, 'environment is invalid'
    end
  end
end
