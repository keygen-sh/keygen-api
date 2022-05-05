# frozen_string_literal: true

class ReleasePlatformPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    true
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.open if
        bearer.nil?

      super
    end
  end
end
