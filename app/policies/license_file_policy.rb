# frozen_string_literal: true

class LicenseFilePolicy < ApplicationPolicy
  def show?
    assert_account_scoped!
    assert_permissions! %w[license.read] + permissions_for_includes

    true
  end

  private

  # We want to assert that the bearer is allowed to read the product,
  # policy, user, group, etc.
  def permissions_for_includes
    perms = []

    perms << 'license.entitlements.read' if resource.includes.include?('entitlements')
    perms << 'group.read' if resource.includes.include?('group')
    perms << 'user.read' if resource.includes.include?('user')
    perms << 'product.read' if resource.includes.include?('product')
    perms << 'policy.read' if resource.includes.include?('policy')

    perms
  end
end
