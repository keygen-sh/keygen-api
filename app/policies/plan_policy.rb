# frozen_string_literal: true

class PlanPolicy < ApplicationPolicy
  def index? = true
  def show?  = true
end
