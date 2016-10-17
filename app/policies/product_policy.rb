class ProductPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
  end

  def show?
    bearer.has_role? :admin or resource == bearer
  end

  def create?
    bearer.has_role? :admin or resource == bearer
  end

  def update?
    bearer.has_role? :admin or resource == bearer
  end

  def destroy?
    bearer.has_role? :admin or resource == bearer
  end

  def generate?
    bearer.has_role? :admin
  end
end
