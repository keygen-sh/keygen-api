class LicensePolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin or bearer.has_role? :product or bearer.has_role? :user
  end

  def show?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def create?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def update?
    bearer.has_role? :admin or resource.product == bearer
  end

  def destroy?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def validate?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def revoke?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end

  def renew?
    bearer.has_role? :admin or resource.user == bearer or resource.product == bearer
  end
end
