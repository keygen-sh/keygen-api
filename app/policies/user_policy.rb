class UserPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
  end

  def show?
    bearer.has_role? :admin or resource == bearer or resource.product == bearer
  end

  def create?
    true
  end

  def update?
    bearer.has_role? :admin or resource == bearer or resource.product == bearer
  end

  def destroy?
    bearer.has_role? :admin or resource == bearer or resource.product == bearer
  end

  def update_password?
    resource == bearer
  end

  def reset_password?
    resource == bearer
  end
end
