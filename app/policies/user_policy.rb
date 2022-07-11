# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.all? { |r|
          r.group_id? && r.group_id.in?(bearer.group_ids) ||
          r.id == bearer.id })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      resource == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.group_id? && resource.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!
    assert_role_ok!

    (bearer.present? && bearer.has_role?(:admin, :developer, :product)) ||
      !account.protected?
  end

  def update?
    assert_account_scoped!
    assert_role_ok!

    return false if
      bearer.has_role?(:read_only)

    bearer.has_role?(:admin, :developer, :sales_agent, :product) ||
      resource == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_role_ok!

    bearer.has_role?(:admin, :developer)
  end

  def generate_token?
    assert_account_scoped!

    resource.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :product)
  end

  def list_tokens?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      resource == bearer
  end

  def show_token?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      resource == bearer
  end

  def invite?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def ban?
    assert_account_scoped!

    resource.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def unban?
    assert_account_scoped!

    resource.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def update_password?
    assert_account_scoped!

    return false if
      resource.has_role?(:read_only)

    resource == bearer
  end

  def reset_password?
    assert_account_scoped!

    return false if
      account.protected? && resource.password.nil?

    return false if
      resource.has_role?(:read_only)

    true
  end

  def me?
    assert_account_scoped!

    resource == bearer
  end

  def change_group?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :product)
  end

  private

  def assert_role_ok!
    return if
      resource.role.nil?

    # Assert that privilege escalation is not occurring by anonymous (sanity check)
    raise Pundit::NotAuthorizedError, reason: 'anonymous is escalating privileges for the resource' if
      bearer.nil? && resource.role.changed?

    # Assert that privilege escalation is not occurring by a bearer (sanity check)
    raise Pundit::NotAuthorizedError, reason: 'bearer is escalating privileges for the resource' if
      (bearer.role.changed? || resource.role.changed?) &&
      bearer.role < resource.role

    # Assert bearer can perform this action on the resource
    raise Pundit::NotAuthorizedError, reason: 'bearer lacks privileges to the resource' if
      bearer.role < resource.role
  end
end
