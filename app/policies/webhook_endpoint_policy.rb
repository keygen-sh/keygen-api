# frozen_string_literal: true

class WebhookEndpointPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer)
  end

  def show?
    bearer.role?(:admin, :developer)
  end

  def create?
    bearer.role?(:admin, :developer)
  end

  def update?
    bearer.role?(:admin, :developer)
  end

  def destroy?
    bearer.role?(:admin, :developer)
  end
end
