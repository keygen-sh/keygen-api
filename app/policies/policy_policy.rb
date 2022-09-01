# frozen_string_literal: true

class PolicyPolicy < ApplicationPolicy
  def index?
    verify_permissions!('policy.read')

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

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def pop?
    assert_account_scoped!
    assert_permissions! %w[
      policy.pool.pop
    ]

    bearer.has_role?(:admin, :developer) ||
      policy.product == bearer
  end

  def attach_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      policy.entitlements.attach
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      policy.product == bearer
  end

  def detach_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      policy.entitlements.detach
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      policy.product == bearer
  end

  def list_entitlements?
    assert_account_scoped!
    assert_permissions! %w[
      policy.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      policy.product == bearer
  end

  def show_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      policy.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      policy.product == bearer
  end
end
