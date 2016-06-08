module AccountScope
  extend ActiveSupport::Concern

  def scope_by_subdomain!
    @current_account = Account.find_by_subdomain! request.subdomains.first
  rescue ActiveRecord::RecordNotFound
    render_not_found "The requested resource requires a valid account subdomain"
  end
end
