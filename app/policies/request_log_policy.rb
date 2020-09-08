# frozen_string_literal: true

class RequestLogPolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer)
  end

  def show?
    bearer.role?(:admin, :developer)
  end

  def count?
    bearer.role?(:admin, :developer)
  end
end
