# frozen_string_literal: true

class SecondFactorPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :user)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :user) &&
      resource.user == bearer
  end

  def create?
    assert_account_scoped!

    resource.user == bearer
  end

  def update?
    assert_account_scoped!

    resource.user == bearer
  end

  def destroy?
    assert_account_scoped!

    resource.user == bearer
  end
end
