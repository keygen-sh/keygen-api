# frozen_string_literal: true

class MetricPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def count?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end
end
