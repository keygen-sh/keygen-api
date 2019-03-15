module RequireActiveSubscription
  IGNORED_ORIGINS = Keygen::Middleware::RequestLogger::IGNORED_ORIGINS

  extend ActiveSupport::Concern

  def require_active_subscription!
    case
    when !current_account.active?
      render_forbidden(
        title: "Account does not have an active subscription",
        detail: "must have an active subscription to access this resource"
      )
      return false
    when !IGNORED_ORIGINS.include?(request.headers['origin']) &&
         current_account.trialing_or_free_tier? &&
         current_account.daily_request_limit_exceeded?
      render_payment_required(
        title: "Daily API request limit reached",
        detail: "Daily API request limit of #{current_account.daily_request_limit.to_s :delimited} has been reached for your account. Please upgrade to a paid subscription at https://app.keygen.sh/subscription to continue. This limit will reset at #{Date.tomorrow.beginning_of_day}."
      )
      return false
    end
  end
end
