# frozen_string_literal: true

class PlanPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!

  authorize :account, allow_nil: true

  def index? = true
  def show?  = true
end
