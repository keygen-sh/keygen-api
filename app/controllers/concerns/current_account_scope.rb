module CurrentAccountScope
  extend ActiveSupport::Concern

  def scope_to_current_account!
    @current_account = Account.find params[:account_id] || params[:id]
  end
end
