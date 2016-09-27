class PolicyPolicy < ApplicationPolicy

  def index?
    bearer.token.can? :admin, resource
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

  def pop?
    bearer.token.can? :admin, resource
  end
end
