# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def attach?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def detach?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end
end
