# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      key.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.product.id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      key.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      key.create
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      key.update
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      key.delete
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end
end
