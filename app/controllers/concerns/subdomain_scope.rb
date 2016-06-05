module SubdomainScope
  extend ActiveSupport::Concern

  included do
    before_action :set_current_account
  end

  private

  def set_current_account
    @current_account = Account.find_by_subdomain! request.subdomains.first
  end
end
