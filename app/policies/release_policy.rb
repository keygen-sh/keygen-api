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
        # Assert current bearer is a user of the product that has a non-expired/suspended
        # license or that the bearer is itself a license for the product that is valid,
        # and then assert that the license satifies all entitlement constraints.
        (bearer.has_role?(:user) && has_valid_license(bearer)) ||
        (bearer.has_role?(:license) && valid_license?(bearer))
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

  def attach_constraints?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def detach_constraints?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  private

  def has_valid_license?(user)
    user.licenses.for_product(resource.product).any? { |l| valid_license?(l) }
  end

  def valid_license?(license)
    within_expiry_window?(license) && has_entitlements?(license) &&
      resource.product == license.product
  end

  def within_expiry_window?(license)
    license.expiry.nil? || resource.created_at < license.expiry
  end

  def has_entitlements?(license)
    (resource.entitlements & license.entitlements).size == resource.entitlements.size
  end
end
