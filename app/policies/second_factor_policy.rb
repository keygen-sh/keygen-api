# frozen_string_literal: true

class SecondFactorPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) &&
      resource.user == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) &&
      resource.user == bearer
  end

  def update?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) &&
      resource.user == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) &&
      resource.user == bearer
  end
end
