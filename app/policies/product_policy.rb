# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def create?
    bearer.role?(:admin, :developer)
  end

  def update?
    bearer.role?(:admin, :developer) ||
      resource == bearer
  end

  def destroy?
    bearer.role?(:admin, :developer)
  end

  def generate?
    bearer.role?(:admin, :developer)
  end
end
