# frozen_string_literal: true

class Product::TokenPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.tokens.read
    ]

    resource.context => [Product => product]
    resource.subject => [Token, *] | [] => tokens

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.product? &&
        product == bearer &&
        tokens.all? { |r| r.bearer_type == Product.name && r.bearer_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.tokens.read
    ]

    resource.context => [Product => product]
    resource.subject => Token => token

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.product? &&
        product == bearer && token.bearer == bearer)
  end

  def create?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      product.tokens.generate
    ]

    resource.context => [Product => product]
    resource.subject => Token

    bearer.has_role?(:admin, :developer)
  end
end
