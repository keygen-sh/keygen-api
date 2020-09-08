# frozen_string_literal: true

class UserPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent, :product) ||
      resource == bearer
  end

  def create?
    (bearer.present? and (bearer.role?(:admin, :developer, :sales_agent, :product))) ||
      !account.protected?
  end

  def update?
    bearer.role?(:admin, :developer, :sales_agent, :product) ||
      resource == bearer
  end

  def destroy?
    bearer.role?(:admin, :developer)
  end

  def read_tokens?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def update_password?
    resource == bearer
  end
end
