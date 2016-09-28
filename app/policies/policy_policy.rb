class PolicyPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
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

  def pop?
    bearer.has_role? :admin or resource.product == bearer
  end
end
