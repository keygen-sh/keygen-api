# frozen_string_literal: true

class EntitlementPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def create?
    bearer.has_role?(:admin, :developer)
  end

  def update?
    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    bearer.has_role?(:admin, :developer)
  end
end
