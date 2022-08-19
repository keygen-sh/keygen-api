# frozen_string_literal: true

class MachineFilePolicy < ApplicationPolicy
  def show?
    verify_permissions!('machine.read', *permissions_for_includes)

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'license' } if record.license == bearer
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

    perms << 'license.entitlements.read' if record.includes.include?('license.entitlements')
    perms << 'license.user.read'         if record.includes.include?('license.user')
    perms << 'license.product.read'      if record.includes.include?('license.product')
    perms << 'license.policy.read'       if record.includes.include?('license.policy')
    perms << 'license.read'              if record.includes.include?('license')
    perms << 'machine.group.read'        if record.includes.include?('group')

    perms
  end
end
