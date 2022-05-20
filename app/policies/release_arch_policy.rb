# frozen_string_literal: true

class ReleaseArchPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    true
  end

  class Scope < ReleasePolicy::Scope; end
end
