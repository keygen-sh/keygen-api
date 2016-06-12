module AccountScope
  extend ActiveSupport::Concern

  included do
    before_action :verify_account_is_activated
  end

  def scope_by_subdomain!
    @current_account = Account.find_by_subdomain! request.subdomains.first
  rescue ActiveRecord::RecordNotFound
    render_not_found detail: "The requested resource requires a valid account subdomain"
  end

  private

  def verify_account_is_activated
    if @current_account && !@current_account.activated?
      render_forbidden title: "Current account is not activated",
        detail: "Please activate your account before accessing this resource"
    end
  end
end
