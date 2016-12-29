module CurrentAccountScope
  extend ActiveSupport::Concern

  def scope_to_current_account!
    @current_account = Account.find params[:account_id] || params[:id]

    if !current_account.beta_user?
      render_forbidden({
        title: "Account is not in the beta program",
        detail: "must have accepted an invite to take part in the beta program",
        source: {
          pointer: "/data/attribute/invited"
        }
      })
    elsif !current_account.active?
      render_forbidden({
        title: "Account does not have an active subscription",
        detail: "must have an active subscription to access this resource",
        source: {
          pointer: "/data/relationship/billing"
        }
      })
    else
      current_account
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found detail: "The requested resource requires a valid account"
  end
end
