# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      machine.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.product.id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.license.user_id == bearer.id }) ||
      (bearer.has_role?(:license) &&
        resource.all? { |r| r.license_id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.all? { |r|
          r.group_id? && r.group_id.in?(bearer.group_ids) ||
          r.license.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      machine.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.group_id? && resource.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      machine.create
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.license.nil? || !resource.license.protected?) && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      machine.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.license.protected? && resource.license == bearer) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      machine.delete
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def checkout?
    assert_account_scoped!
    assert_permissions! %w[
      machine.check-out
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def ping?
    assert_account_scoped!
    assert_permissions! %w[
      machine.heartbeat.ping
    ]

    bearer.has_role?(:admin, :developer) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end
  alias_method :ping_heartbeat?, :ping?

  def reset?
    assert_account_scoped!
    assert_permissions! %w[
      machine.heartbeat.reset
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end
  alias_method :reset_heartbeat?, :reset?

  def generate_offline_proof?
    assert_account_scoped!
    assert_permissions! %w[
      machine.proofs.generate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def change_group?
    assert_account_scoped!
    assert_permissions! %w[
      machine.group.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end
end
