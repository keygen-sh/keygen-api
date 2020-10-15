# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer)
  end

  def update?
    bearer.has_role?(:admin, :developer) ||
      resource == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer)
  end

  def generate?
    bearer.has_role?(:admin, :developer)
  end

  def me?
    resource == bearer
  end
end
