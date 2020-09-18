# frozen_string_literal: true

class SecondFactorPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :user)
  end

  def show?
    resource.user == bearer
  end

  def create?
    resource.user == bearer
  end

  def update?
    resource.user == bearer
  end

  def destroy?
    resource.user == bearer
  end
end
