# frozen_string_literal: true

class LicenseFilePolicy < ApplicationPolicy
  def show?
    verify_permissions!('license.read', *permissions_for_includes)

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
  # policy, user, group, etc.
  def permissions_for_includes
    perms = []

    perms << 'entitlement.read' if record.includes.include?('entitlements')
    perms << 'group.read'       if record.includes.include?('group')
    perms << 'user.read'        if record.includes.include?('user')
    perms << 'product.read'     if record.includes.include?('product')
    perms << 'policy.read'      if record.includes.include?('policy')

    perms
  end
end
