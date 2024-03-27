# frozen_string_literal: true

class LicenseFilePolicy < ApplicationPolicy
  def show?
    verify_permissions!('license.read', *permissions_for_includes)
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || bearer.licenses.exists?(record.license_id)
      allow!
    in role: Role(:license) if record.license == bearer
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
    perms << 'environment.read' if record.includes.include?('environment')
    perms << 'group.read'       if record.includes.include?('group')
    perms << 'user.read'        if record.includes.include?('owner')
    perms << 'product.read'     if record.includes.include?('product')
    perms << 'policy.read'      if record.includes.include?('policy')

    perms
  end
end
