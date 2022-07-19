# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy

  def index?
    assert_account_scoped!
    assert_permissions! %w[
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.policy.product_id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.user_id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.all? { |r|
          r.group_id? && r.group_id.in?(bearer.group_ids) ||
          r.user_id == bearer.id })
  end

  def show?
    assert_account_scoped!
    assert_permissions! %w[
      license.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.group_id? && resource.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!
    assert_permissions! %w[
      license.create
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.policy.nil? || !resource.policy.protected?) && resource.user == bearer) ||
      (resource.product.nil? || resource.product == bearer)
  end

  def update?
    assert_account_scoped!
    assert_permissions! %w[
      license.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!
    assert_permissions! %w[
      license.delete
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def check_in?
    assert_account_scoped!
    assert_permissions! %w[
      license.check-in
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def revoke?
    assert_account_scoped!
    assert_permissions! %w[
      license.revoke
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def renew?
    assert_account_scoped!
    assert_permissions! %w[
      license.renew
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def suspend?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def reinstate?
    assert_account_scoped!
    assert_permissions! %w[
      license.reinstate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def quick_validate_by_id?
    assert_account_scoped!
    assert_permissions! %w[
      license.validate
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_id?
    assert_account_scoped!
    assert_permissions! %w[
      license.validate
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_key?
    assert_account_scoped!
    assert_permissions! %w[
      license.validate
    ]

    # NOTE(ezekg) We have optional authn
    return true unless
      bearer.present?

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def checkout?
    assert_account_scoped!
    assert_permissions! %w[
      license.check-out
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def increment?
    assert_account_scoped!
    assert_permissions! %w[
      license.usage.increment
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def decrement?
    assert_account_scoped!
    assert_permissions! %w[
      license.usage.decrement
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def reset?
    assert_account_scoped!
    assert_permissions! %w[
      license.usage.reset
    ]

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def change_policy?
    assert_account_scoped!
    assert_permissions! %w[
      license.policy.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def change_user?
    assert_account_scoped!
    assert_permissions! %w[
      license.user.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def change_group?
    assert_account_scoped!
    assert_permissions! %w[
      license.group.update
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_token?
    assert_account_scoped!
    assert_permissions! %w[
      license.tokens.generate
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_tokens?
    assert_account_scoped!
    assert_permissions! %w[
      license.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def show_token?
    assert_account_scoped!
    assert_permissions! %w[
      license.tokens.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def attach_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      license.entitlements.attach
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def detach_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      license.entitlements.detach
    ]

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_entitlements?
    assert_account_scoped!
    assert_permissions! %w[
      license.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def show_entitlement?
    assert_account_scoped!
    assert_permissions! %w[
      license.entitlements.read
    ]

    bearer.has_role?(:admin, :developer, :read_only, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def me?
    assert_account_scoped!
    assert_permissions! %w[
      license.read
    ]

    resource == bearer
  end
end
