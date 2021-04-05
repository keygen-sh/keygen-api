# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.policy.nil? || !resource.policy.protected?) && resource.user == bearer) ||
      (resource.product.nil? || resource.product == bearer)
  end

  def update?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def check_in?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def revoke?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def renew?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def suspend?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def reinstate?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def quick_validate_by_id?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_id?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_key?
    true
  end

  def increment?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def decrement?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def reset?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def upgrade?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def transfer?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_token?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_tokens?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def show_token?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def attach_entitlement?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def detach_entitlement?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_entitlements?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def show_entitlement?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def me?
    resource == bearer
  end
end
