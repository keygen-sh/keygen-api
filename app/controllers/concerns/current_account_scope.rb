# frozen_string_literal: true

module CurrentAccountScope
  extend ActiveSupport::Concern

  def scope_to_current_account!
    account_id = params[:account_id] || params[:id]
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      FindByAliasService.new(Account, account_id, aliases: :slug).call
    end

    Keygen::Store::Request.store[:current_account] = account

    @current_account = account
  end
end
