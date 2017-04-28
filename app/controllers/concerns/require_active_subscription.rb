module RequireActiveSubscription
  extend ActiveSupport::Concern

  def require_active_subscription!
    if !current_account.active?
      render_forbidden({
        title: "Account does not have an active subscription",
        detail: "must have an active subscription to access this resource"
      })
    end
  end
end
