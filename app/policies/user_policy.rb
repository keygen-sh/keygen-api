# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product) ||
      resource == bearer
  end

  def create?
    assert_account_scoped!

    return false if resource.has_role?(:admin) &&
                    !bearer&.has_role?(:admin)

    (bearer.present? && bearer.has_role?(:admin, :developer, :product)) ||
      !account.protected?
  end

  def update?
    assert_account_scoped!

    return false if resource.has_role?(:admin) &&
                    !bearer.has_role?(:admin)

    bearer.has_role?(:admin, :developer, :sales_agent, :product) ||
      resource == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer)
  end

  def read_tokens?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def update_password?
    assert_account_scoped!

    resource == bearer
  end

  def me?
    assert_account_scoped!

    resource == bearer
  end
end
