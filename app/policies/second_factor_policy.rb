# frozen_string_literal: true

class SecondFactorPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      second-factor.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      second-factor.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :user) &&
      resource.user == bearer
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      second-factor.create
    ]

    return false if
      bearer.has_role?(:read_only)

    resource.user == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      second-factor.update
    ]

    return false if
      bearer.has_role?(:read_only)

    resource.user == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      second-factor.delete
    ]

    return false if
      bearer.has_role?(:read_only)

    resource.user == bearer
  end
end
