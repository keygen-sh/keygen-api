# frozen_string_literal: true

class PolicyPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product
  end

  def show?
    bearer.role? :admin or resource.product == bearer
  end

  def create?
    bearer.role? :admin or resource.product == bearer
  end

  def update?
    bearer.role? :admin or resource.product == bearer
  end

  def destroy?
    bearer.role? :admin or resource.product == bearer
  end

  def pop?
    bearer.role? :admin or resource.product == bearer
  end
end
