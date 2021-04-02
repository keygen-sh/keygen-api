# frozen_string_literal: true

class LicenseEntitlementPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user, :license)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end
end
