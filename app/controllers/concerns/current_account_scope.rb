# frozen_string_literal: true

module CurrentAccountScope
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks

    ACCOUNT_SCOPE_INTERNAL_DOMAINS = %w[keygen.sh]
    ACCOUNT_SCOPE_CACHE_TTL        = 15.minutes

    # Define callback system for current account to allow controllers to run certain
    # callbacks before and after the current account has been set. For example, we
    # use this to validate signature-related headers, since we need to know the
    # account, but we don't want to validate after the action has been processed
    # since an error may need to be returned due to a malformed header.
    define_callbacks :current_account_scope

    def scope_to_current_account!
      run_callbacks :current_account_scope do
        account_id = params[:account_id] ||
                     params[:id]

        # Adds CNAME support for custom domains
        account = find_by_account_domain(request.domain) ||
                  find_by_account_id!(account_id)

        Current.account = account

        # TODO(ezekg) Should we deprecate this?
        @current_account = account
      end
    end

    def self.before_current_account(callback)
      set_callback :current_account_scope, :before, callback
    end

    def self.after_current_account(callback)
      set_callback :current_account_scope, :after, callback
    end

    private

    def find_by_account_domain!(domain)
      raise Keygen::Error::InvalidAccountDomainError, 'domain is required' unless
        domain.present?

      raise Keygen::Error::InvalidAccountDomainError, 'domain is invalid' if
        domain.in?(ACCOUNT_SCOPE_INTERNAL_DOMAINS)

      cache_key = Account.cache_key(domain)

      Rails.cache.fetch(cache_key, skip_nil: true, expires_in: ACCOUNT_SCOPE_CACHE_TTL) do
        FindByAliasService.call(scope: Account, identifier: domain, aliases: :domain)
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
        FindByAliasService.call(scope: Account, identifier: id, aliases: :slug)
      end
    end

    def find_by_account_id(...)
      find_by_account_id!(...)
    rescue Keygen::Error::InvalidAccountIdError,
           Keygen::Error::NotFoundError
      nil
    end
  end
end
