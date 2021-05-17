# frozen_string_literal: true

class ReleasePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def check_for_update?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer ||
      (
        resource.entitlement_constraints.any? &&
        (resource.entitlements & bearer.entitlements).any?
      )
  end

  def download_file?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer ||
      (
        resource.entitlement_constraints.any? &&
        (resource.entitlements & bearer.entitlements).any?
      )
  end

  def upload_file?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def yank_file?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end
end
