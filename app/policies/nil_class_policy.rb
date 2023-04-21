# frozen_string_literal: true

class NilClassPolicy < ApplicationPolicy
  def index?   = deny!
  def show?    = deny!
  def create?  = deny!
  def update?  = deny!
  def destroy? = deny!
end
