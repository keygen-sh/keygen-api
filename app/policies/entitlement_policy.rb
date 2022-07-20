# frozen_string_literal: true

class EntitlementPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      entitlement.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      entitlement.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product)
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      entitlement.create
    ]

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      entitlement.update
    ]

    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      entitlement.delete
    ]

    bearer.has_role?(:admin, :developer)
  end
end
