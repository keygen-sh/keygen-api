class WebhookEventPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin
  end

  def show?
    bearer.role? :admin or bearer.role? :product
  end

  def destroy?
    bearer.role? :admin
  end

  def retry?
    bearer.role? :admin
  end
end
