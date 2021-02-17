# frozen_string_literal: true

class RequestLogPolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer)
  end

  def show?
    bearer.has_role?(:admin, :developer)
  end

  def count?
    bearer.has_role?(:admin, :developer)
  end
end
