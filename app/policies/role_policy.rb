# frozen_string_literal: true

class RolePolicy < ApplicationPolicy

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.resource == bearer ||
      resource.resource.products.include?(bearer)
  end
end
