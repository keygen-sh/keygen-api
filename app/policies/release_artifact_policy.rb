# frozen_string_literal: true

class ReleaseArtifactPolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_permissions! %w[
      artifact.read
    ]

    true
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      artifact.download
      artifact.read
    ]

    # FIXME(ezekg) Authorization should be moved from release policy to here
    # Delegate to release policy
    release_policy = ReleasePolicy.new(context, resource.release)
    return false if
      release_policy.nil?

    release_policy.download?
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      artifact.create
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      artifact.update
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      artifact.delete
    ]

    bearer.has_role?(:admin, :developer) ||
      resource.product == bearer
  end

  class Scope < ReleasePolicy::Scope
    def resolve
      return scope.open.published.uploaded if
        bearer.nil?

      @scope = case
               when bearer.has_role?(:admin, :developer, :product)
                 scope
               else
                 scope.published.uploaded
               end

      super
    end
  end
end
