# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product) ||
      resource == bearer
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

    bearer.has_role?(:admin, :developer, :sales_agent, :product) ||
      resource == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_role_ok!

    bearer.has_role?(:admin, :developer)
  end

  def read_tokens?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def update_password?
    assert_account_scoped!

    resource == bearer
  end

  def me?
    assert_account_scoped!

    resource == bearer
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
