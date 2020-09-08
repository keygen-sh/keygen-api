# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent, :product, :user)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.bearer == bearer
  end

  def regenerate?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.bearer == bearer
  end

  def revoke?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.bearer == bearer
  end
end
