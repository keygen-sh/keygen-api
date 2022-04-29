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
        Current.account ||= ResolveAccountService.call!(request:)

        # TODO(ezekg) Should we deprecate this?
        @current_account = Current.account
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
