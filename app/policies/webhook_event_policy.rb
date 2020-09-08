# frozen_string_literal: true

class WebhookEventPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer)
  end

  def show?
    bearer.has_role?(:admin, :developer, :product)
  end

  def destroy?
    bearer.has_role?(:admin, :developer)
  end

  def retry?
    bearer.has_role?(:admin, :developer)
  end
end
