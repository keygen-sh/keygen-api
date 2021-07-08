# frozen_string_literal: true

class ReleaseChannelPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    true
  end
end
