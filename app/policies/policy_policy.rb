# frozen_string_literal: true

class PolicyPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.product_id == bearer.id })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def pop?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def attach_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def detach_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_entitlements?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def show_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end
end
