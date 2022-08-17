# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  def index?
    verify_permissions!('user.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('user.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' }
      allow!
    in role: { name: 'user' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    assert_account_scoped!
    assert_role_ok!
    assert_permissions! %w[
      user.create
    ]

    (bearer.present? && bearer.has_role?(:admin, :developer, :product)) ||
      !account.protected?
  end

  def update?
    assert_account_scoped!
    assert_role_ok!
    assert_permissions! %w[
      user.update
    ]

    return false if
      bearer.has_role?(:read_only)

    bearer.has_role?(:admin, :developer, :sales_agent, :product) ||
      user == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_role_ok!
    assert_permissions! %w[
      user.delete
    ]

    bearer.has_role?(:admin, :developer)
  end

  def generate_token?
    assert_account_scoped!
    assert_permissions! %w[
      user.tokens.generate
    ]

    user.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :product)
  end

  def list_tokens?
    assert_account_scoped!
    assert_permissions! %w[
      user.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      user == bearer
  end

  def show_token?
    assert_account_scoped!
    assert_permissions! %w[
      user.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      user == bearer
  end

  def invite?
    assert_account_scoped!
    assert_permissions! %w[
      user.invite
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def ban?
    assert_account_scoped!
    assert_permissions! %w[
      user.ban
    ]

    user.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def unban?
    assert_account_scoped!
    assert_permissions! %w[
      user.unban
    ]

    user.has_role?(:user) &&
      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def update_password?
    assert_account_scoped!
    assert_permissions! %w[
      user.password.update
    ]

    return false if
      user.has_role?(:read_only)

    user == bearer
  end

  def reset_password?
    assert_account_scoped!
    assert_permissions! %w[
      user.password.reset
    ]

    return false if
      user.has_role?(:user) && account.protected? && !user.password?

    return false if
      user.has_role?(:read_only)

    true
  end

  def me?
    assert_account_scoped!
    assert_permissions! %w[
      user.read
    ]

    user == bearer
  end

  def change_group?
    assert_account_scoped!
    assert_permissions! %w[
      user.group.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :product)
  end

  private

  def assert_role_ok!
    return if
      user.role.nil?

    # Assert that privilege escalation is not occurring by anonymous (sanity check)
    raise Pundit::NotAuthorizedError, policy: self, message: 'anonymous is escalating privileges for the user' if
      bearer.nil? && user.role.changed? && !user.role.user?

    return if
      bearer.nil?

    # Assert that privilege escalation is not occurring by a bearer (sanity check)
    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer is escalating privileges for the user' if
      (bearer.role.changed? || user.role.changed?) &&
      bearer.role < user.role

    # Assert bearer can perform this action on the user
    raise Pundit::NotAuthorizedError, policy: self, message: 'bearer lacks privileges to the user' if
      bearer.role < user.role
  end
end
