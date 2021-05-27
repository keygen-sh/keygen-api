# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end
end
