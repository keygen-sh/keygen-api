# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product) ||
      resource == bearer
  end

  def create?
    return false if resource.has_role?(:admin) &&
                    !bearer.has_role?(:admin)

    (bearer.present? && bearer.has_role?(:admin, :developer, :product)) ||
      !account.protected?
  end

  def update?
    return false if resource.has_role?(:admin) &&
                    !bearer.has_role?(:admin)

    bearer.has_role?(:admin, :developer, :sales_agent, :product) ||
      resource == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer)
  end

  def read_tokens?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def update_password?
    resource == bearer
  end
end
