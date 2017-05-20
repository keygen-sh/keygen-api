class LicensePolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product or bearer.role? :user
  end

  def show?
    bearer.role? :admin or resource.user == bearer or resource.product == bearer
  end

  def create?
    bearer.role? :admin or (!resource.policy.protected? and resource.user == bearer) or resource.product == bearer
  end

  def update?
    bearer.role? :admin or resource.product == bearer
  end

  def destroy?
    bearer.role? :admin or (!resource.policy.protected? and resource.user == bearer) or resource.product == bearer
  end

  def check_in?
    bearer.role? :admin or (!resource.policy.protected? and resource.user == bearer) or resource.product == bearer
  end

  def revoke?
    bearer.role? :admin or (!resource.policy.protected? and resource.user == bearer) or resource.product == bearer
  end

  def renew?
    bearer.role? :admin or (!resource.policy.protected? and resource.user == bearer) or resource.product == bearer
  end

  def suspend?
    bearer.role? :admin or resource.product == bearer
  end

  def reinstate?
    bearer.role? :admin or resource.product == bearer
  end

  def validate_by_id?
    bearer.role? :admin or resource.user == bearer or resource.product == bearer
  end

  def validate_by_key?
    true
  end
end
