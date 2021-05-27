# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def generate?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def me?
    assert_account_scoped!

    resource == bearer
  end
end
