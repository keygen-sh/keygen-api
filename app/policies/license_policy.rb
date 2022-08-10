# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_types! License
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
    assert_type! License
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
    assert_type! License
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
    assert_type! License
    assert_permissions! %w[
      license.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_type! License
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
    assert_type! License
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
    assert_type! License
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
    assert_type! License
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
    assert_type! License
    assert_permissions! %w[
      license.suspend
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def reinstate?
    assert_account_scoped!
    assert_authenticated!
    assert_type! License
    assert_permissions! %w[
      license.reinstate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def quick_validate_by_id?
    assert_account_scoped!
    assert_authenticated!
    assert_type! License
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
    assert_type! License
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
    assert_type! License
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
    assert_type! License
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
    assert_type! License
    assert_permissions! %w[
      license.read
    ]

    license == bearer
  end

  class UsagePolicy < ApplicationPolicy
    def increment?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! :usage
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
      assert_context! [License]
      assert_type! :usage
      assert_permissions! %w[
        license.usage.decrement
      ]

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def reset?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! :usage
      assert_permissions! %w[
        license.usage.reset
      ]

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    private

    def license = resource.context.first
  end

  class TokenPolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_types! Token
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
      assert_context! [License]
      assert_type! Token
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
      assert_context! [License]
      assert_type! Token
      assert_permissions! %w[
        license.tokens.generate
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end

    private

    def license = resource.context.first
    def tokens  = resource.subject
    def token   = resource.subject
  end

  class EntitlementPolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_types! LicenseEntitlement
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
      assert_type! LicenseEntitlement
      assert_context! [License]
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
      assert_context! [License]
      assert_type! Entitlement
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
      assert_context! [License]
      assert_type! Entitlement
      assert_permissions! %w[
        license.entitlements.detach
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end

    private

    def license = resource.context.first
  end

  class ProductPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Product

      authorize! license => :show?,
                 product => :show?
    end

    private

    def license = resource.context.first
    def product = resource.subject
  end

  class PolicyPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Policy

      authorize! license => :show?,
                 policy  => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Policy
      assert_permissions! %w[
        license.policy.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        (!policy.protected? && license.user == bearer) ||
        (license.product == bearer &&
          policy.product == bearer)
    end

    private

    def license = resource.context.first
    def policy  = resource.subject
  end

  class UserPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! User

      authorize! license => :show?,
                 user    => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! User
      assert_permissions! %w[
        license.user.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end

    private

    def license = resource.context.first
    def user    = resource.subject
  end

  class GroupPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Group

      authorize! license => :show?,
                 group   => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Group
      assert_permissions! %w[
        license.group.update
      ]

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end

    private

    def license = resource.context.first
    def group   = resource.subject
  end

  class MachinePolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_types! Machine

      authorize! license  => :show?,
                 machines => :index?
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_context! [License]
      assert_type! Machine

      authorize! license => :show?,
                 machine => :show?
    end

    private

    def license  = resource.context.first
    def machines = resource.subject
    def machine  = resource.subject
  end

  private

  def licenses = resource.subject
  def license  = resource.subject
end
