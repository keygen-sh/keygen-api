# frozen_string_literal: true

class EntitlementPolicy < ApplicationPolicy
  def index?
    verify_permissions!('entitlement.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
      allow!
    in role: Role(:user | :license) if record.all? { _1.id.in?(bearer.entitlement_ids) }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('entitlement.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
      allow!
    in role: Role(:user | :license) if record.id.in?(bearer.entitlement_ids)
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('entitlement.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('entitlement.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('entitlement.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      deny!
    end
  end
end
