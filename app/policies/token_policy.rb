# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.bearer == bearer
  end

  def regenerate?
    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end

  def revoke?
    bearer.has_role?(:admin, :developer) ||
      resource.bearer == bearer
  end
end
