# frozen_string_literal: true

class NilClassPolicy < ApplicationPolicy
  def index?   = false
  def show?    = false
  def create?  = false
  def update?  = false
  def destroy? = false
end
