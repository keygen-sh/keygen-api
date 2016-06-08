class LicensePolicy < ApplicationPolicy

  def index?
    user.admin?
  end

  def show?
    user.admin? or record.user == user
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
end
