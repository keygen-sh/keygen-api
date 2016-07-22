class UserPolicy < ApplicationPolicy

  def index?
    user.admin?
  end

  def show?
    user.admin? or record == user
  end

  def create?
    true
  end

  def update?
    user.admin? or record == user
  end

  def destroy?
    user.admin?
  end

  def update_password?
    record == user
  end

  def reset_password?
    record == user
  end
end
