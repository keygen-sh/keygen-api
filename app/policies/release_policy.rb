# frozen_string_literal: true

class ReleasePolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_permissions! %w[
      release.read
    ]

    true
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      release.read
    ]

    true
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      release.create
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      release.update
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      release.delete
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def download?
    assert_account_scoped!
    assert_permissions! %w[
      release.download
      release.read
    ]

    # We don't need to authenticate if product is open distribution, as long as the
    # release doesn't have any entitlement constraints.
    return true if
      resource.product.open_distribution? &&
      resource.constraints.none?

    # Otherwise, we require authentication.
    return false if
      bearer.nil?

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.product == bearer ||
      (
        !resource.product.closed_distribution? && (
          # Assert current bearer is a user of the product that has a non-expired/suspended
          # license or that the bearer is itself a license for the product that is valid,
          # and then assert that the license satisfies all entitlement constraints.
          (bearer.has_role?(:user) && has_valid_license?(bearer)) ||
          (bearer.has_role?(:license) && valid_license?(bearer))
        )
      )
  end

  def upgrade?
    assert_account_scoped!
    assert_permissions! %w[
      release.upgrade
      release.read
    ]

    download?
  end

  def upload?
    assert_account_scoped!
    assert_permissions! %w[
      release.upload
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def publish?
    assert_account_scoped!
    assert_permissions! %w[
      release.publish
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def yank?
    assert_account_scoped!
    assert_permissions! %w[
      release.yank
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def list_entitlements?
    assert_account_scoped!
    assert_permissions! %w[
      release.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only) ||
      resource.product == bearer
  end

  def show_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      release.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only) ||
      resource.product == bearer
  end

  def list_constraints?
    assert_account_scoped!
    assert_permissions! %w[
      release.constraints.read
    ]

    bearer.has_role?(:admin, :developer, :read_only) ||
      resource.product == bearer
  end

  def show_constraint?
    assert_account_scoped!
    assert_permissions! %w[
      release.constraints.read
    ]

    bearer.has_role?(:admin, :developer, :read_only) ||
      resource.product == bearer
  end

  def attach_constraints?
    assert_account_scoped!
    assert_permissions! %w[
      release.constraints.attach
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def detach_constraints?
    assert_account_scoped!
    assert_permissions! %w[
      release.constraints.detach
    ]

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

    return true if
      license.allow_access?

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
      return scope.open.published if
        bearer.nil?

      @scope = case
               when bearer.has_role?(:admin, :developer, :product)
                 scope
               else
                 scope.published
               end

      super
    end
  end
end
