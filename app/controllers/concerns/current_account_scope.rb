# frozen_string_literal: true

module CurrentAccountScope
  extend ActiveSupport::Concern

  included do
    include ActiveSupport::Callbacks

    define_callbacks :current_account_scope

    def scope_to_current_account!
      run_callbacks :current_account_scope do
        account_id = params[:account_id] || params[:id]
        account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
          FindByAliasService.new(Account, account_id, aliases: :slug).call
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
