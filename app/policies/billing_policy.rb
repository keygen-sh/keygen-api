class BillingPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.role? :admin
  end

  def create?
    false
  end

  def update?
    bearer.role? :admin
  end

  def destroy?
    bearer.role? :admin
  end
end
