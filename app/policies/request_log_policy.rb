class RequestLogPolicy < ApplicationPolicy

  def index?
    bearer.role? :admin
  end

  def show?
    bearer.role? :admin
  end

  def count?
    bearer.role? :admin
  end
end
