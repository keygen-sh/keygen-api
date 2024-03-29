# frozen_string_literal: true

module CurrentAccountConstraints
  CURRENT_ACCOUNT_IGNORED_ORIGINS = %w[https://app.keygen.sh https://dist.keygen.sh].freeze

  extend ActiveSupport::Concern

  def require_active_subscription!
    case
    when !current_account.active?
      render_forbidden(
        title: "Account does not have an active subscription",
        detail: "must have an active subscription to access this resource"
      )
      return false
    when !CURRENT_ACCOUNT_IGNORED_ORIGINS.include?(request.headers['origin']) &&
         current_account.trialing_or_free? &&
         current_account.daily_request_limit_exceeded?
      render_payment_required(
        title: "Daily API request limit reached",
        detail: "Daily API request limit of #{current_account.daily_request_limit.to_fs(:delimited)} has been reached for your account. Please add a payment method at https://app.keygen.sh/billing to continue. This limit will reset at #{Date.tomorrow.beginning_of_day}."
      )
      return false
    end
  end

  def require_paid_subscription!
    case
    when !current_account.paid?
      render_forbidden(
        title: "Account does not have a paid subscription",
        detail: "must have a paid subscription to access this resource"
      )

      return false
    end
  end

  def require_ent_subscription!
    case
    when !current_account.ent?
      render_forbidden(
        title: "Account does not have an Ent subscription",
        detail: "must have a paid subscription on an Ent tier to access this resource"
      )

      return false
    end
  end
end
