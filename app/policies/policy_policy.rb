# frozen_string_literal: true

class PolicyPolicy < ApplicationPolicy
  def index?
    verify_permissions!('policy.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { _1.product_id == bearer.id }
      allow!
    in role: Role(:license) if record == [bearer.policy]
      allow!
    in role: Role(:user) if record_ids & bearer.policy_ids == record_ids
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('policy.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if bearer.policies.exists?(record.id)
      allow!
    in role: Role(:license) if record == bearer.policy
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('policy.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('policy.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('policy.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end
end
