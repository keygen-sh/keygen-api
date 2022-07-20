# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-event.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :product)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-event.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :product)
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-event.delete
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  def retry?
    assert_account_scoped!
    assert_permissions! %w[
      webhook-event.retry
    ]

    bearer.has_role?(:admin, :developer, :product)
  end
end
