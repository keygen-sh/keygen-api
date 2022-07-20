# frozen_string_literal: true

class GroupOwnerPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_permissions! %w[
      group.owner.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      group.owner.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product)
  end
end
