# frozen_string_literal: true

class EntitlementPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end
end
