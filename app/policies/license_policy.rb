# frozen_string_literal: true

class LicensePolicy < ApplicationPolicy

  def index?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent, :product, :user)
  end

  def show?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def create?
    bearer.role?(:admin, :developer, :sales_agent) ||
      ((resource.policy.nil? || !resource.policy.protected?) && resource.user == bearer) ||
      resource.product == bearer
  end

  def update?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def destroy?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def check_in?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def revoke?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def renew?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def suspend?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def reinstate?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def quick_validate_by_id?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_id?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource == bearer
  end

  def validate_by_key?
    true
  end

  def increment?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource == bearer
  end

  def decrement?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def reset?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def upgrade?
    bearer.role?(:admin, :developer, :sales_agent) ||
      (!resource.policy.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def transfer?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_token?
    bearer.role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def list_tokens?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end

  def show_token?
    bearer.role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.product == bearer
  end
end
