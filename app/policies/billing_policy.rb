class BillingPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.token.can? :admin, resource
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
end
