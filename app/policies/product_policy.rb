# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def products    = resource.subjects
  def product     = resource.subject
  def product_ids = products.collect(:id)

  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.read
    ]

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

    bearer.has_role?(:admin, :developer)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.update
    ]

    bearer.has_role?(:admin, :developer) ||
      product == bearer
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

    product == bearer
  end

  class TokenPolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        product.tokens.read
      ]

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        (bearer.has_role?(:product) &&
          product.all? { |r| r.bearer_type == Product.name && r.bearer_id == bearer.id })
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        product.tokens.read
      ]

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        product.bearer == bearer
    end

    def create?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        product.tokens.generate
      ]

      bearer.has_role?(:admin, :developer)
    end
  end
end
