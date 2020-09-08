# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def create?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def update?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def destroy?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end
end
