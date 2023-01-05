# frozen_string_literal: true

class ResolveAccountService < BaseService
  ACCOUNT_SCOPE_INVALID_DOMAIN_RE = /keygen\.sh\z/
  ACCOUNT_SCOPE_CACHE_TTL         = 15.minutes

  def initialize(request:)
    @request = request
  end

  def call!
    account_id = request.params[:account_id] ||
                 request.params[:id]

    # Adds CNAME support for custom domains
    account = find_by_account_domain(request.host) ||
              find_by_account_id!(account_id)

    account
  end

  def call
    account_id = request.params[:account_id] ||
                 request.params[:id]

    account = find_by_account_domain(request.host) ||
              find_by_account_id(account_id)

    account
  end

  private

  attr_reader :request

  def find_by_account_domain!(domain)
    raise Keygen::Error::InvalidAccountDomainError, 'domain is required' unless
      domain.present?

    raise Keygen::Error::InvalidAccountDomainError, 'domain is invalid' if
      domain.match?(ACCOUNT_SCOPE_INVALID_DOMAIN_RE)

    cache_key = Account.cache_key("cname:#{domain}")

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: ACCOUNT_SCOPE_CACHE_TTL) do
      # FIXME(ezekg) Remove domain column after all customers are migrated to cname
      FindByAliasService.call(Account, id: domain, aliases: %i[cname domain])
    end
  end

  def find_by_account_domain(...)
    find_by_account_domain!(...)
  rescue Keygen::Error::InvalidAccountDomainError,
         Keygen::Error::NotFoundError
    nil
  end

  def find_by_account_id!(id)
    raise Keygen::Error::InvalidAccountIdError, 'id is required' unless
      id.present?

    cache_key = Account.cache_key(id)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: ACCOUNT_SCOPE_CACHE_TTL) do
      FindByAliasService.call(Account, id:, aliases: :slug)
    end
  end

  def find_by_account_id(...)
    find_by_account_id!(...)
  rescue Keygen::Error::InvalidAccountIdError,
         Keygen::Error::NotFoundError
    nil
  end
end
