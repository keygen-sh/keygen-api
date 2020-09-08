# frozen_string_literal: true

class WebhookEndpointPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer)
  end

  def show?
    bearer.has_role?(:admin, :developer)
  end

  def create?
    bearer.has_role?(:admin, :developer)
  end

  def update?
    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    bearer.has_role?(:admin, :developer)
  end
end
