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

  def download?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer ||
      (
        resource.entitlement_constraints.any? &&
        (resource.entitlements & bearer.entitlements).any?
      )
  end

  def upload?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def yank?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def list_constraints?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def show_constraint?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def attach_constraint?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def detach_constraint?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end
end
