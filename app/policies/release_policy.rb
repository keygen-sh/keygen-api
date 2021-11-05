# frozen_string_literal: true

class ReleasePolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    true
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def upsert?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def download?
    assert_account_scoped!

    return resource.product.open_distribution? if
      bearer.nil?

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer ||
      (
        # Assert current bearer is a user of the product that has a non-expired/suspended
        # license or that the bearer is itself a license for the product that is valid,
        # and then assert that the license satifies all entitlement constraints.
        (bearer.has_role?(:user) && has_valid_license?(bearer)) ||
        (bearer.has_role?(:license) && valid_license?(bearer))
      )
  end

  def upload?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def yank?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def list_constraints?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def show_constraint?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def attach_constraints?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def detach_constraints?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  private

  def has_valid_license?(user)
    licenses = user.licenses.preload(:product, :policy).for_product(resource.product)

    licenses.any? { |l| valid_license?(l) }
  end

  def valid_license?(license)
    resource.product == license.product &&
      !license.suspended? &&
      within_expiry_window?(license) &&
      has_entitlements?(license)
  end

  def within_expiry_window?(license)
    return true if
      license.expiry.nil?

    return false if
      license.revoke_access? &&
      license.expired?

    resource.created_at < license.expiry
  end

  def has_entitlements?(license)
    (resource.entitlements & license.entitlements).size == resource.entitlements.size
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.open if bearer.nil?

      super
    end
  end
end
