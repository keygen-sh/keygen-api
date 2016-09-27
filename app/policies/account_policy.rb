class AccountPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.token.can? :admin, resource
  end

  def create?
    true
  end

  def update?
    bearer.token.can? :admin, resource
  end

  def destroy?
    bearer.token.can? :admin, resource
  end

  def pause?
    bearer.token.can? :admin, resource
  end

  def resume?
    bearer.token.can? :admin, resource
  end

  def cancel?
    bearer.token.can? :admin, resource
  end
end
