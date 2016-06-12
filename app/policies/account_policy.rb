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
end
