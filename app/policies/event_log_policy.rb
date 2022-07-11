# frozen_string_literal: true

class EventLogPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def count?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :read_only)
  end
end
