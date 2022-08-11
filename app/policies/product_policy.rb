# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    resource.subject => [Product, *] | [] => products
    product_ids = products.collect(&:id)

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.license? && products == [bearer.product]) ||
      (bearer.user? &&
        product_ids & bearer.product_ids == product_ids)
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    resource.subject => Product => product

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.product? && product == bearer) ||
      (bearer.license? && product == bearer.product) ||
      (bearer.user? && bearer.products.exists?(product.id))
  end

  def create?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.create
    ]

    resource.subject => Product => product

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.update
    ]

    resource.subject => Product => product

    bearer.has_role?(:admin, :developer) ||
      product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.delete
    ]

    resource.subject => Product => product

    bearer.has_role?(:admin, :developer)
  end

  def me?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

    resource.subject => Product => product

    product == bearer
  end
end
