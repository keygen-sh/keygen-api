# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy
  def licenses = resource.subjects
  def license  = resource.subject

  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        licenses.all? { _1.policy.product_id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        licenses.all? { _1.user_id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        licenses.all? {
          _1.group_id? && _1.group_id.in?(bearer.group_ids) ||
          _1.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      license.user == bearer ||
      license.product == bearer ||
      license == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        license.group_id? && license.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.create
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((license.policy.nil? || !license.policy.protected?) && license.user == bearer) ||
      (license.product.nil? || license.product == bearer)
  end

  def update?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.delete
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!license.policy.protected? && license.user == bearer) ||
      license.product == bearer
  end

  def check_in?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.check-in
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!license.policy.protected? && license.user == bearer) ||
      license.product == bearer ||
      license == bearer
  end

  def revoke?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.revoke
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!license.policy.protected? && license.user == bearer) ||
      license.product == bearer
  end

  def renew?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.renew
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!license.policy.protected? && license.user == bearer) ||
      license.product == bearer
  end

  def suspend?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.suspend
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def reinstate?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.reinstate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def quick_validate_by_id?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.validate
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      license.user == bearer ||
      license.product == bearer ||
      license == bearer
  end

  def validate_by_id?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.validate
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      license.user == bearer ||
      license.product == bearer ||
      license == bearer
  end

  def validate_by_key?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.validate
      license.read
    ]

    # NOTE(ezekg) We have optional authn
    return true unless
      bearer.present?

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      license.user == bearer ||
      license.product == bearer ||
      license == bearer
  end

  def checkout?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.check-out
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!license.policy.protected? && license.user == bearer) ||
      license.product == bearer ||
      license == bearer
  end

  def me?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.read
    ]

    license == bearer
  end

  class UsagePolicy < ApplicationPolicy
    def license = resource.context.first

    def increment?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.usage.increment
      ]

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        (!license.policy.protected? && license.user == bearer) ||
        license.product == bearer ||
        license == bearer
    end

    def decrement?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.usage.decrement
      ]

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def reset?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.usage.reset
      ]

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        license.product == bearer
    end
  end

  class TokenPolicy < ApplicationPolicy
    def license = resource.context.first
    def tokens  = resource.subjects
    def token   = resource.subject

    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.tokens.read
      ]

      authorize! license => :show?,
                 tokens  => :index

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.tokens.read
      ]

      authorize! license => :show?,
                 token   => :index

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def generate?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.tokens.generate
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class EntitlementPolicy < ApplicationPolicy
    def license = resource.context.first

    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.entitlements.read
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.user == bearer ||
        license.product == bearer ||
        license == bearer
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.entitlements.read
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.user == bearer ||
        license.product == bearer ||
        license == bearer
    end

    def attach?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.entitlements.attach
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end

    def detach?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.entitlements.detach
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class ProductPolicy < ApplicationPolicy
    def license = resource.context.first
    def product = resource.subject

    def show?
      authorize! license => :show?,
                 product => :show?
    end
  end

  class PolicyPolicy < ApplicationPolicy
    def license = resource.context.first
    def policy  = resource.subject

    def show?
      authorize! license => :show?,
                 policy  => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.policy.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        (!policy.protected? && license.user == bearer) ||
        (license.product == bearer &&
          policy.product == bearer)
    end
  end

  class UserPolicy < ApplicationPolicy
    def license = resource.context.first
    def user    = resource.subject

    def show?
      authorize! license => :show?,
                 user    => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.user.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class GroupPolicy < ApplicationPolicy
    def license = resource.context.first
    def group   = resource.subject

    def show?
      authorize! license => :show?,
                 group   => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.group.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class MachinePolicy < ApplicationPolicy
    def license  = resource.context.first
    def machines = resource.subjects
    def machine  = resource.subject

    def index?
      authorize! license  => :show?,
                 machines => :index?
    end

    def show?
      authorize! license => :show?,
                 machine => :show?
    end
  end
end
