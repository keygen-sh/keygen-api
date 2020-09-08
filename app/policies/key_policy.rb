# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end
end
