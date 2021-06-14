# frozen_string_literal: true

module CurrentAccountScope
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks

    # Define callback system for current account to allow controllers to run certain
    # callbacks before and after the current account has been set. For example, we
    # use this to validate signature-related headers, since we need to know the
    # account, but we don't want to validate after the action has been processed
    # since an error may need to be returned due to a malformed header.
    define_callbacks :current_account_scope

    def scope_to_current_account!
      run_callbacks :current_account_scope do
        account_id = params[:account_id] || params[:id]
        account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
          FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
        end

        Keygen::Store::Request.store[:current_account] = account

        @current_account = account
      end
    end

    def self.before_current_account(callback)
      set_callback :current_account_scope, :before, callback
    end

    def self.after_current_account(callback)
      set_callback :current_account_scope, :after, callback
    end
  end
end
