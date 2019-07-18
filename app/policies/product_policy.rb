# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin
  end

  def show?
    bearer.role? :admin or resource == bearer
  end

  def create?
    bearer.role? :admin
  end

  def update?
    bearer.role? :admin or resource == bearer
  end

  def destroy?
    bearer.role? :admin or resource == bearer
  end

  def generate?
    bearer.role? :admin
  end
end
