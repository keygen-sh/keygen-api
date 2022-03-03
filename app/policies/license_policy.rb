# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy

  def index?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (bearer.has_role?(:product) &&
        resource.all? { |r| r.policy.product_id == bearer.id }) ||
      (bearer.has_role?(:user) &&
        resource.all? { |r| r.user_id == bearer.id }) ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.any?   { |r| r.group_id? } &&
        resource.filter { |r| r.group_id? }
                .all?   { |r| r.group_id.in?(bearer.group_ids) })
  end

  def show?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer ||
      (bearer.has_role?(:user) && bearer.group_ids.any? &&
        resource.group_id? && resource.group_id.in?(bearer.group_ids))
  end

  def create?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.policy.nil? || !resource.policy.protected?) && resource.user == bearer) ||
      (resource.product.nil? || resource.product == bearer)
  end

  def update?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def destroy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def check_in?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def revoke?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def renew?
    assert_account_scoped!

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

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def quick_validate_by_id?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_id?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_key?
    assert_account_scoped!

    # NOTE(ezekg) We have optional authn
    return true unless
      bearer.present?

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def increment?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def decrement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def reset?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def change_policy?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def change_user?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def change_group?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_token?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_tokens?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def show_token?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def attach_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def detach_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_entitlements?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def show_entitlement?
    assert_account_scoped!

    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def me?
    assert_account_scoped!

    resource == bearer
  end
end
