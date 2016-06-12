class AccountPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    user.admin?
  end

  def create?
    false
  end

  def update?
    user.admin?
  end

  def destroy?
    false
  end
end
