# frozen_string_literal: true

class RolePolicy < ApplicationPolicy

  def show?
    bearer.role? :admin or resource.resource == bearer or resource.resource.products.include? bearer
  end
end
