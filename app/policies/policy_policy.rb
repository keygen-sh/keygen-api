# frozen_string_literal: true

class PolicyPolicy < ApplicationPolicy
  def index?
    verify_permissions!('policy.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product_id == bearer.id }
      allow!
    in role: { name: 'license' } if record == [bearer.policy]
      allow!
    in role: { name: 'user' } if record_ids & bearer.policy_ids == record_ids
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
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if bearer.policies.exists?(record.id)
      allow!
    in role: { name: 'license' } if record == bearer.policy
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('policy.create')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('policy.update')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('policy.delete')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end
end
