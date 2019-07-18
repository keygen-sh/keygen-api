# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product or bearer.role? :user
  end

  def show?
    bearer.role? :admin or resource.bearer == bearer
  end

  def regenerate?
    bearer.role? :admin or resource.bearer == bearer
  end

  def revoke?
    bearer.role? :admin or resource.bearer == bearer
  end
end
