# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.bearer == bearer
  end

  def regenerate?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end

  def revoke?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end
end
