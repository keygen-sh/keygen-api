module CurrentAccountScope
  SCOPE_HEADER_KEY = "Keygen-Account".freeze

  extend ActiveSupport::Concern

  def scope_to_current_account!
    @current_account = Account.find_by_name! request.headers.fetch(SCOPE_HEADER_KEY, nil)

    if current_account.active?
      current_account
    else
      render_forbidden({
        title: "Account does not have an active subscription",
        detail: "must have an active subscription to access this resource",
        source: {
          pointer: "/data/relationship/billing"
        }
      })
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found detail: "The requested resource requires a valid account"
  end
end
