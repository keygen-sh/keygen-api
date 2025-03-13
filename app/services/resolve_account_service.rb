# frozen_string_literal: true

class ResolveAccountService < BaseService
  ACCOUNT_INTERNAL_DOMAIN_RE = /#{Regexp.escape(Keygen::DOMAIN)}\z/.freeze
  ACCOUNT_CACHE_TTL          = 15.minutes

  def initialize(request:)
    @request = request
  end

  def call!
    case
    when Keygen.singleplayer?
      account_id = request.params[:account_id] ||
                   ENV['KEYGEN_ACCOUNT_ID']
      raise Keygen::Error::InvalidAccountIdError, 'account is required' unless
        account_id.present?

      account = find_by_account_id!(account_id)
      raise Keygen::Error::InvalidAccountIdError, "account is invalid (expected #{ENV['KEYGEN_ACCOUNT_ID']})" unless
        account.id == ENV['KEYGEN_ACCOUNT_ID']

      account
    when Keygen.multiplayer?
      account_id   = request.params[:account_id]
      account_host = request.host

      account = find_by_account_cname(account_host) ||
                find_by_account_id!(account_id)

      account
    end
  end

  def call
    call!
  rescue Keygen::Error::InvalidAccountDomainError,
         Keygen::Error::InvalidAccountIdError,
         Keygen::Error::NotFoundError
    nil
  end

  private

  attr_reader :request

  def find_by_account_cname!(domain)
    raise Keygen::Error::InvalidAccountDomainError, 'domain is required' unless
      domain.present?

    raise Keygen::Error::InvalidAccountDomainError, 'domain is internal' if
      domain in ACCOUNT_INTERNAL_DOMAIN_RE

    cache_key = Account.cache_key("cname:#{domain}")

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: ACCOUNT_CACHE_TTL) do
      # FIXME(ezekg) Remove domain column after all customers are migrated to cname
      FindByAliasService.call(Account, id: domain, aliases: %i[cname domain])
    end
  end

  def find_by_account_cname(...)
    find_by_account_cname!(...)
  rescue Keygen::Error::InvalidAccountDomainError,
         Keygen::Error::NotFoundError
    nil
  end

  def find_by_account_id!(id)
    raise Keygen::Error::InvalidAccountIdError, 'account is required' unless
      id.present?

    cache_key = Account.cache_key(id)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: ACCOUNT_CACHE_TTL) do
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
