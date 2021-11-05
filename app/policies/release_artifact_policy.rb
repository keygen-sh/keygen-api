# frozen_string_literal: true

class ReleaseArtifactPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    # Delegate to release policy
    release_policy = ReleasePolicy.new(context, resource.release)
    return false if
      release_policy.nil?

    release_policy.download?
  end

  class Scope < ReleasePolicy::Scope; end
end
