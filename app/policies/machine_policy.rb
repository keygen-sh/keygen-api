class MachinePolicy < ApplicationPolicy

  def index?
    bearer.token.can? :admin, resource
  end

  def show?
    bearer.token.can? :admin, resource or resource.bearer == bearer
  end

  def create?
    bearer.token.can? :admin, resource or resource.bearer == bearer
  end

  def update?
    bearer.token.can? :admin, resource or resource.bearer == bearer
  end

  def destroy?
    bearer.token.can? :admin, resource
  end
end
