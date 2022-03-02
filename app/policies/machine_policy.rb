# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.product.id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.license.user_id == bearer.id }) ||
      (bearer.has_role?(:license) &&
        resource.all? { |r| r.license_id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.filter { |r| r.group_id? }
                .all? { |r| r.group_id.in?(bearer.group_ids) })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer ||
      (bearer.has_role?(:user) &&
        resource.group_id? && resource.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.license.nil? || !resource.license.protected?) && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def ping_heartbeat?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def reset_heartbeat?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_offline_proof?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end
end
