class MachinePolicy < ApplicationPolicy

  def index?
    bearer.role? :admin or bearer.role? :product or bearer.role? :user or bearer.role? :license
  end

  def show?
    bearer.role? :admin or resource.user == bearer or resource.product == bearer or resource.license == bearer
  end

  def create?
    bearer.role? :admin or ((resource.license.nil? or !resource.license.protected?) and resource.user == bearer) or resource.product == bearer or resource.license == bearer
  end

  def update?
    bearer.role? :admin or (!resource.license.protected? and resource.user == bearer) or resource.product == bearer
  end

  def destroy?
    bearer.role? :admin or (!resource.license.protected? and resource.user == bearer) or resource.product == bearer or resource.license == bearer
  end
end
