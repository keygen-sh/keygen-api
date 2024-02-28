# frozen_string_literal: true

class MachineFilePolicy < ApplicationPolicy
  def show?
    verify_permissions!('machine.read', *permissions_for_includes)
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer
      allow!
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  private

  # We want to assert that the bearer is allowed to read the product,
  # policy, user, group, etc. includes.
  def permissions_for_includes
    perms = []

    perms << 'entitlement.read' if record.includes.include?('license.entitlements')
    perms << 'user.read'        if record.includes.include?('license.owner')
    perms << 'product.read'     if record.includes.include?('license.product')
    perms << 'policy.read'      if record.includes.include?('license.policy')
    perms << 'environment.read' if record.includes.include?('environment')
    perms << 'license.read'     if record.includes.include?('license')
    perms << 'component.read'   if record.includes.include?('components')
    perms << 'group.read'       if record.includes.include?('group')

    perms
  end
end
