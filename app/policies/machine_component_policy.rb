# frozen_string_literal: true

class MachineComponentPolicy < ApplicationPolicy
  def index?
    verify_permissions!('component.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { _1.product == bearer }
      allow!
    in role: Role(:user) if record.all? { _1.user == bearer }
      allow!
    in role: Role(:license) if record.all? { _1.license == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('component.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.user == bearer
      allow!
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('component.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.user == bearer
      !record.license&.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('component.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.user == bearer
      !record.license.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('component.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.user == bearer
      !record.license.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end
end
