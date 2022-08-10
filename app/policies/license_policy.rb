# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy
  def index?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.read
    ]

    resource.subject => [License, *] | [] => licenses

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

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.delete
    ]

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      license.product == bearer
  end

  def reinstate?
    assert_account_scoped!
    assert_authenticated!
    assert_permissions! %w[
      license.reinstate
    ]

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      license.user == bearer ||
      license.product == bearer ||
      license == bearer
  end

  def validate_by_key?
    assert_account_scoped!
    assert_permissions! %w[
      license.validate
      license.read
    ]

    resource.subject => License => license

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

    resource.subject => License => license

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

    resource.subject => License => license

    license == bearer
  end

  class UsagePolicy < ApplicationPolicy
    def increment?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.usage.increment
      ]

      resource.context => [License => license]
      resource.subject => :usage

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

      resource.context => [License => license]
      resource.subject => :usage

      bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def reset?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.usage.reset
      ]

      resource.context => [License => license]
      resource.subject => :usage

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
      assert_permissions! %w[
        license.tokens.read
      ]

      resource.context => [License => license]
      resource.subject => [Token, *] | [] => tokens

      authorize! license => :show?,
                 tokens => :index

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def show?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.tokens.read
      ]

      resource.context => [License => license]
      resource.subject => Token => token

      authorize! license => :show?,
                 token => :index

      bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
        license.product == bearer
    end

    def generate?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.tokens.generate
      ]

      resource.context => [License => license]
      resource.subject => Token

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class EntitlementPolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.entitlements.read
      ]

      resource.context => [License => license]
      resource.subject => [Entitlement, *]

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

      resource.context => [License => license]
      resource.subject => Entitlement

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

      resource.context => [License => license]
      resource.subject => Entitlement

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

      resource.context => [License => license]
      resource.subject => Entitlement

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class ProductPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!

      resource.context => [License => license]
      resource.subject => Policy => policy

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

      resource.context => [License => license]
      resource.subject => Policy => policy

      authorize! license => :show?,
                 policy => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.policy.update
      ]

      resource.context => [License => license]
      resource.subject => Policy

      authorize! license => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        (!policy.protected? && license.user == bearer) ||
        (license.product == bearer &&
          policy.product == bearer)
    end
  end

  class UserPolicy < ApplicationPolicy
    def show?
      assert_account_scoped!
      assert_authenticated!

      resource.context => [License => license]
      resource.subject => User | nil => user

      authorize! license => :show?,
                 user => :show?
    end

    def update?
      assert_account_scoped!
      assert_authenticated!
      assert_permissions! %w[
        license.user.update
      ]

      resource.context => [License => license]
      resource.subject => User | nil => user

      authorize! license => :show?,
                 user => :show?

      bearer.has_role?(:admin, :developer, :sales_agent) ||
        license.product == bearer
    end
  end

  class MachinePolicy < ApplicationPolicy
    def index?
      assert_account_scoped!
      assert_authenticated!

      resource.context => [License => license]
      resource.subject => [Machine, *] | [] => machines

      authorize! license  => :show?,
                 machines => :index?
    end

    def show?
      assert_account_scoped!
      assert_authenticated!

      resource.context => [License => license]
      resource.subject => Machine => machine

      authorize! license => :show?,
                 machine => :show?
    end
  end
end
