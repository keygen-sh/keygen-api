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
        (
          # Assert current bearer is a user of the product that has a non-expired/suspended
          # license or that the bearer is itselt a license for the product that is valid
          (bearer.has_role?(:user) && bearer.licenses.for_product(resource.product).any? { |l| !l.expired? && !l.suspended? }) ||
          (bearer.has_role?(:license) && !bearer.expired? && !bearer.suspended? && bearer.product == resource.product)
        ) &&
        # Assert bearer satisfies all entitlement constraints
        (resource.entitlements & bearer.entitlements).size == resource.entitlements.size
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
