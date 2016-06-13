class AccountPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    user.admin?
  end

  def create?
    true
  end

  def update?
    user.admin?
  end

  def destroy?
    user.admin?
  end

  def pause?
    user.admin?
  end

  def resume?
    user.admin?
  end

  def cancel?
    user.admin?
  end
end
