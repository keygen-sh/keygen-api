class LicensePolicy < ApplicationPolicy

  def index?
    bearer.token.can? :admin, resource
  end

  def show?
    bearer.token.can? :admin, resource or resource.bearer == bearer
  end

  def create?
    bearer.token.can? :admin, resource
  end

  def update?
    bearer.token.can? :admin, resource
  end

  def destroy?
    bearer.token.can? :admin, resource
  end

  def verify?
    bearer.token.can? :admin, resource or resource.bearer == bearer
  end

  def revoke?
    bearer.token.can? :admin, resource
  end

  def renew?
    bearer.token.can? :admin, resource
  end
end
