class KeyPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin or bearer.has_role? :product
  end

  def show?
    bearer.has_role? :admin or resource.product == bearer
  end

  def create?
    bearer.has_role? :admin or resource.product == bearer
  end

  def update?
    bearer.has_role? :admin or resource.product == bearer
  end

  def destroy?
    bearer.has_role? :admin or resource.product == bearer
  end
end
