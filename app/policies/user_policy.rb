class UserPolicy < ApplicationPolicy

  def index?
    bearer.token.can? :admin, resource
  end

  def show?
    bearer.token.can? :admin, resource or resource == bearer
  end

  def create?
    true
  end

  def update?
    bearer.token.can? :admin, resource or resource == bearer
  end

  def destroy?
    bearer.token.can? :admin, resource
  end

  def update_password?
    resource == bearer
  end

  def reset_password?
    resource == bearer
  end
end
