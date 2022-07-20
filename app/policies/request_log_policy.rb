# frozen_string_literal: true

class RequestLogPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      request-log.read
    ]

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      request-log.read
    ]

    bearer.has_role?(:admin, :developer, :read_only)
  end

  def count?
    assert_account_scoped!
    assert_permissions! %w[
      request-log.read
    ]

    bearer.has_role?(:admin, :developer, :read_only)
  end
end
