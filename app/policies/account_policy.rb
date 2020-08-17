# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy

  def show?
    bearer.role? :admin
  end

  def create?
    true
  end

  def update?
    bearer.role? :admin
  end

  def destroy?
    false
  end

  def manage?
    bearer.role? :admin
  end

  def pause?
    bearer.role? :admin
  end

  def resume?
    bearer.role? :admin
  end

  def cancel?
    bearer.role? :admin
  end

  def renew?
    bearer.role? :admin
  end
end
