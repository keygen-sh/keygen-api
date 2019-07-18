# frozen_string_literal: true

class PlanPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end
end
