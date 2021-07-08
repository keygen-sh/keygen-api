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
end
