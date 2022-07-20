# frozen_string_literal: true

class EventLogPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      event-log.read
    ]

    return false unless
      account.ent_tier?

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      event-log.read
    ]

    return false unless
      account.ent_tier?

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def count?
    assert_account_scoped!
    assert_permissions! %w[
      event-log.read
    ]

    return false unless
      account.ent_tier?

    bearer.has_role?(:admin, :developer, :read_only)
  end
end
