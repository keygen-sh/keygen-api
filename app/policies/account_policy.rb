class AccountPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.has_role? :admin
  end

  def create?
    true
  end

  def update?
    bearer.has_role? :admin
  end

  def destroy?
    bearer.has_role? :admin
  end

  def pause?
    bearer.has_role? :admin
  end

  def resume?
    bearer.has_role? :admin
  end

  def cancel?
    bearer.has_role? :admin
  end
end
