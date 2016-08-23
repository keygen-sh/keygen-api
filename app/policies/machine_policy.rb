class MachinePolicy < ApplicationPolicy

  def index?
    user.admin?
  end

  def show?
    user.admin? or record.user == user
  end

  def create?
    user.admin? or record.user == user
  end

  def update?
    user.admin? or record.user == user
  end

  def destroy?
    user.admin?
  end
end
