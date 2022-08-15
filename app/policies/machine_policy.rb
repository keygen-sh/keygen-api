# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy
  def index?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product.id == bearer.id }
      allow!
    in role: { name: 'user' }, group_ids: [*] if record.all? { (_1.group_id? && _1.group_id.in?(bearer.group_ids)) || _1.license.user_id == bearer.id }
      allow!
    in role: { name: 'user' } if record.all? { _1.license.user_id == bearer.id }
      allow!
    in role: { name: 'license' } if record.all? { _1.license_id == bearer.id }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' }, group_ids: [*] if record.group_id? && record.group_id.in?(bearer.group_ids)
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      machine.create
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((machine.license.nil? || !machine.license.protected?) && machine.user == bearer) ||
      machine.product == bearer ||
      machine.license == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      machine.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!machine.license.protected? && machine.license == bearer) ||
      (!machine.license.protected? && machine.user == bearer) ||
      machine.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      machine.delete
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!machine.license.protected? && machine.user == bearer) ||
      machine.product == bearer ||
      machine.license == bearer
  end

  def checkout?
    assert_account_scoped!
    assert_permissions! %w[
      machine.check-out
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!machine.license.protected? && machine.user == bearer) ||
      machine.product == bearer ||
      machine.license == bearer
  end

  def ping?
    assert_account_scoped!
    assert_permissions! %w[
      machine.heartbeat.ping
    ]

    bearer.has_role?(:admin, :developer) ||
      (!machine.license.protected? && machine.user == bearer) ||
      machine.product == bearer ||
      machine.license == bearer
  end
  alias_method :ping_heartbeat?, :ping?

  def reset?
    assert_account_scoped!
    assert_permissions! %w[
      machine.heartbeat.reset
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      machine.product == bearer
  end
  alias_method :reset_heartbeat?, :reset?

  def generate_offline_proof?
    assert_account_scoped!
    assert_permissions! %w[
      machine.proofs.generate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!machine.license.protected? && machine.user == bearer) ||
      machine.product == bearer ||
      machine.license == bearer
  end

  def change_group?
    assert_account_scoped!
    assert_permissions! %w[
      machine.group.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      machine.product == bearer
  end
end
