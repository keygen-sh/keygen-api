class LicensePolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
  end

  def show?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def create?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def update?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def destroy?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def verify?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def revoke?
    bearer.has_role? :admin
  end

  def renew?
    bearer.has_role? :admin
  end
end
