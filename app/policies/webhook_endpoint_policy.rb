class WebhookEndpointPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
  end

  def show?
    bearer.has_role? :admin
  end

  def create?
    bearer.has_role? :admin
  end

  def update?
    bearer.has_role? :admin
  end

  def destroy?
    bearer.has_role? :admin
  end
end
