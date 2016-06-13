module AccountScope
  extend ActiveSupport::Concern

  def scope_by_subdomain!
    @current_account = Account.find_by_subdomain! request.subdomains.first

    if @current_account.activated?
      @current_account
    else
      render_forbidden({
        title: "Current account is not activated",
        detail: "You must activate your account before accessing this resource"
      })
    end
  rescue ActiveRecord::RecordNotFound
    render_not_found detail: "The requested resource requires a valid account subdomain"
  end
end
