class BillingPolicy < ApplicationPolicy

  def index?
    false
  end

  def show?
    bearer.has_role? :admin
  end

  def create?
    false
  end

  def update?
    bearer.has_role? :admin
  end

  def destroy?
    bearer.has_role? :admin
  end
end
