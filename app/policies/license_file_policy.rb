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
    lic   = resource.subject
    perms = []

    perms << 'license.entitlements.read' if lic.includes.include?('entitlements')
    perms << 'group.read' if lic.includes.include?('group')
    perms << 'user.read' if lic.includes.include?('user')
    perms << 'product.read' if lic.includes.include?('product')
    perms << 'policy.read' if lic.includes.include?('policy')

    perms
  end
end
