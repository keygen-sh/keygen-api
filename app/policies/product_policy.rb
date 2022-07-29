# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.license? && resource == [bearer.product]) ||
      (bearer.user? &&
        resource_ids & bearer.product_ids == resource_ids)
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.product? && resource == bearer) ||
      (bearer.license? && resource == bearer.product) ||
      (bearer.user? && bearer.products.exists?(resource.id))
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
