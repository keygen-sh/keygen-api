# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer)
  end

  def show?
    bearer.role?(:admin, :developer, :product)
  end

  def destroy?
    bearer.role?(:admin, :developer)
  end

  def retry?
    bearer.role?(:admin, :developer)
  end
end
