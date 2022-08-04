# frozen_string_literal: true

class Product::TokenPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.bearer_type == Product.name && r.bearer_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.bearer == bearer
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
