# frozen_string_literal: true

class BillingPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin)
  end

  def create?
    false
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin)
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin)
  end
end
