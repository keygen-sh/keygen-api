# frozen_string_literal: true

class MachineFilePolicy < ApplicationPolicy
  def show?
    assert_account_scoped!
    assert_permissions! %w[machine.read] + permissions_for_includes

    true
  end

  private

  # We want to assert that the bearer is allowed to read the product,
  # policy, user, group, etc.
  def permissions_for_includes
    perms = []

    perms << 'license.entitlements.read' if resource.includes.include?('license.entitlements')
    perms << 'user.read' if resource.includes.include?('license.user')
    perms << 'product.read' if resource.includes.include?('license.product')
    perms << 'policy.read' if resource.includes.include?('license.policy')
    perms << 'license.read' if resource.includes.include?('license')
    perms << 'group.read' if resource.includes.include?('group')

    perms
  end
end
