# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def index?
    false
  end

  def show?
    assert_permissions! %w[
      account.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent)
  end

  def create?
    true
  end

  def update?
    assert_permissions! %w[
      account.update
    ]

    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    false
  end
end
