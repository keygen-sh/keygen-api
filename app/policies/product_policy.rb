# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent)
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def create?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.create
    ]

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.update
    ]

    bearer.has_role?(:admin, :developer) ||
      resource == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.delete
    ]

    bearer.has_role?(:admin, :developer)
  end

  def me?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    resource == bearer
  end
end
