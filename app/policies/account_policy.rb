# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent)
  end

  def create?
    true
  end

  def update?
    bearer.has_role?(:admin, :developer)
  end

  def destroy?
    false
  end

  def manage?
    bearer.has_role?(:admin)
  end

  def pause?
    bearer.has_role?(:admin)
  end

  def resume?
    bearer.has_role?(:admin)
  end

  def cancel?
    bearer.has_role?(:admin)
  end

  def renew?
    bearer.has_role?(:admin)
  end
end
