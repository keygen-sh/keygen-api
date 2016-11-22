class TokenPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product or bearer.role? :user
  end

  def show?
    bearer == resource.bearer
  end

  def regenerate?
    bearer == resource.bearer
  end

  def revoke?
    bearer == resource.bearer
  end
end
