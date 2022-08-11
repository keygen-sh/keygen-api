# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      group.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      (bearer.has_role?(:user) &&
        groups.all? { _1.id == bearer.group_id || _1.id.in?(bearer.group_ids) }) ||
      (bearer.has_role?(:license) &&
        groups.all? { _1.id == bearer.group_id })
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      group.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
      (bearer.has_role?(:user) &&
        (group.id == bearer.group_id || group.id.in?(bearer.group_ids))) ||
      (bearer.has_role?(:license) &&
        group.id == bearer.group_id)
  end

  def create?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      group.create
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      group.update
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      group.delete
    ]

    bearer.has_role?(:admin, :developer, :product)
  end

  class GroupOwnerPolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        group.owners.read
      ]

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
        (bearer.has_role?(:user) &&
          group.all? { _1.id == bearer.group_id || _1.id.in?(bearer.group_ids) })
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        group.owners.read
      ]

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent, :product) ||
        (bearer.has_role?(:user) &&
          (group.id == bearer.group_id || group.id.in?(bearer.group_ids)))
    end

    def attach?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        group.owners.attach
      ]

      bearer.has_role?(:admin, :developer, :product)
    end

    def detach?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        group.owners.detach
      ]

      bearer.has_role?(:admin, :developer, :product)
    end
  end
end
