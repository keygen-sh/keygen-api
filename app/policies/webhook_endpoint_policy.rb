# frozen_string_literal: true

class WebhookEndpointPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin
  end

  def show?
    bearer.role? :admin
  end

  def create?
    bearer.role? :admin
  end

  def update?
    bearer.role? :admin
  end

  def destroy?
    bearer.role? :admin
  end
end
