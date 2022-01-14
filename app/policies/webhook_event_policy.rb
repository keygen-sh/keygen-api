# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end

  def retry?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :product)
  end
end
