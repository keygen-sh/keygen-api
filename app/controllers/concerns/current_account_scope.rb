# frozen_string_literal: true

module CurrentAccountScope
  extend ActiveSupport::Concern

  def scope_to_current_account!
    account_id = params[:account_id] || params[:id]
    account = Rails.cache.fetch(Account.cache_key(account_id), expires_in: 15.minutes) do
      Account.find account_id
    end

    Keygen::Store::Request.store[:current_account] = account

    @current_account = account
  end
end
