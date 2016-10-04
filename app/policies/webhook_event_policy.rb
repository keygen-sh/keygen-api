class WebhookEventPolicy < ApplicationPolicy

  def index?
    bearer.has_role? :admin
  end

  def show?
    bearer.has_role? :admin
  end
end
