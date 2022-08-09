# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy
  def machines = resource.subjects
  def machine  = resource.subject

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      machine.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        machines.all? { _1.product.id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        machines.all? { _1.license.user_id == bearer.id }) ||
      (bearer.has_role?(:license) &&
        machines.all? { _1.license_id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        machines.all? {
          _1.group_id? && _1.group_id.in?(bearer.group_ids) ||
          _1.license.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      machine.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      machine.user == bearer ||
      machine.product == bearer ||
      machine.license == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        machine.group_id? && machine.group_id.in?(bearer.group_ids))
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
