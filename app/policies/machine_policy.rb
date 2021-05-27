# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user, :license)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer
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
