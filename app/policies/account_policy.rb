class AccountPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.role? :admin
  end

  def create?
    true
  end

  def update?
    bearer.role? :admin
  end

  def destroy?
    bearer.role? :admin
  end

  def pause?
    bearer.role? :admin
  end

  def resume?
    bearer.role? :admin
  end

  def cancel?
    bearer.role? :admin
  end
end
