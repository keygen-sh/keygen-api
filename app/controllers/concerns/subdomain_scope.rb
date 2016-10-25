module SubdomainScope
  extend ActiveSupport::Concern

  def scope_by_subdomain!
    @current_account = Account.find_by_subdomain! request.subdomains.first

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
    render_not_found detail: "The requested resource requires a valid account subdomain"
  end
end
