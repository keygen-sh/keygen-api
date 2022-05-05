# frozen_string_literal: true

class ReleaseArtifactPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!

    true
  end

  def show?
    assert_account_scoped!

    # FIXME(ezekg) Authorization should be moved from release policy to here
    # Delegate to release policy
    release_policy = ReleasePolicy.new(context, resource.release)
    return false if
      release_policy.nil?

    release_policy.download?
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def delete?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  class Scope < ReleasePolicy::Scope
    def resolve
      return scope.open.uploaded if
        bearer.nil?

      @scope = case
               when bearer.has_role?(:admin, :developer, :product)
                 scope
               else
                 scope.uploaded
               end

      super
    end
  end
end
