class UserPolicy < ApplicationPolicy

  def index?
    user.admin?
  end

  def show?
    user.admin? or record == user
  end

  def create?
    user.admin?
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def update_password?
    user.admin? or record == user
  end

  def reset_password?
    user.admin? or record == user
  end
end
