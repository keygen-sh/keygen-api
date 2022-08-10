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
    mac   = resource.subject
    perms = []

    perms << 'license.entitlements.read' if mac.includes.include?('license.entitlements')
    perms << 'user.read' if mac.includes.include?('license.user')
    perms << 'product.read' if mac.includes.include?('license.product')
    perms << 'policy.read' if mac.includes.include?('license.policy')
    perms << 'license.read' if mac.includes.include?('license')
    perms << 'group.read' if mac.includes.include?('group')

    perms
  end
end
