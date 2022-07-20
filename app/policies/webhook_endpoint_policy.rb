# frozen_string_literal: true

class WebhookEndpointPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-endpoint.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :product)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-endpoint.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :product)
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-endpoint.create
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-endpoint.update
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-endpoint.delete
    ]

    bearer.has_role?(:admin, :developer, :product)
  end
end
