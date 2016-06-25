module AccountScope
  extend ActiveSupport::Concern

  def scope_by_subdomain!
    @current_account = Account.find_by_subdomain! request.subdomains.first

    if @current_account.activated?
      if %w[active pending].include? @current_account.status
        @current_account
      else
        render_forbidden({
          title: "Account has been #{@current_account.status}",
          detail: "must be active",
          source: {
            pointer: "/data/attributes/status"
          }
        })
      end
    else
      render_forbidden({
        title: "Account is not activated",
        detail: "must be activated to access this resource",
        source: {
          pointer: "/data/attributes/activated"
        }
      })
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found detail: "The requested resource requires a valid account subdomain"
  end
end
