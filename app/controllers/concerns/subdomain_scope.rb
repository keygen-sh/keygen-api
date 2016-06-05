module SubdomainScope
  extend ActiveSupport::Concern

  class_methods do
    def scope_by_subdomain
      before_action :set_current_account
    end
  end

  private

  def set_current_account
    @current_account = Account.find_by_subdomain! request.subdomains.first
  end
end
