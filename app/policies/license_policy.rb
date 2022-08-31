# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[validate? validate_key?]

  def index?
    verify_permissions!('license.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product == bearer }
      allow!
    in role: { name: 'user' } if record.all? { _1.user == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('license.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'license' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('license.create')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.policy&.protected?
    else
      deny!
    end
  end

  def update?
    verify_permissions!('license.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('license.delete')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.policy.protected?
    else
      deny!
    end
  end

  def check_out?
    verify_permissions!('license.check-out')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.policy.protected?
    in role: { name: 'license' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def check_in?
    verify_permissions!('license.check-in')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.policy.protected?
    in role: { name: 'license' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def validate?
    verify_permissions!('license.validate')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'license' } if record == bearer
      allow!
    else
      deny!
    end
  end

  def validate_key?
    # FIXME(ezekg) We allow validation without authentication. I'd like
    #              to deprecate this behavior in favor of using license
    #              key authentication.
    allow! if
      bearer.nil? || record.nil?

    allowed_to?(:validate?, inline_reasons: true)
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
