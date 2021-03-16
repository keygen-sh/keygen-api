# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy

  def index?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :user, :license)
  end

  def show?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      resource.user == bearer ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def create?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      ((resource.license.nil? || !resource.license.protected?) && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def update?
    bearer.has_role?(:admin, :developer, :sales_agent, :support_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer
  end

  def destroy?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def ping_heartbeat?
    bearer.has_role?(:admin, :developer) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end

  def reset_heartbeat?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      resource.product == bearer
  end

  def generate_offline_proof?
    bearer.has_role?(:admin, :developer, :sales_agent) ||
      (!resource.license.protected? && resource.user == bearer) ||
      resource.product == bearer ||
      resource.license == bearer
  end
end
