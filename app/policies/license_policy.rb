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

  def verify_license?
    user.admin? or record.user == user
  end

  def revoke_license?
    user.admin?
  end

  def renew_license?
    user.admin?
  end
end
