# frozen_string_literal: true

class MachineProcessPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.product.id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.license.user_id == bearer.id }) ||
      (bearer.has_role?(:license) &&
        resource.all? { |r| r.license.id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.all? { |r|
          r.group.present? && r.group.id.in?(bearer.group_ids) ||
          r.license.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.group.present? && resource.group.id.in?(bearer.group_ids))
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
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def ping?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end
end
