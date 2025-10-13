# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy
  def index?
    verify_permissions!('machine.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.all? { it.product == bearer }
      allow!
    in role: Role(:user) if record.all? { it.owner == bearer || it.license.owner == bearer || it.id.in?(bearer.machine_ids) }
      allow!
    in role: Role(:license) if record.all? { it.license == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('machine.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || record.license.owner == bearer || bearer.machines.exists?(record.id)
      allow!
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('machine.create', *permissions_for_create)
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || record.license&.owner == bearer
      !record.license&.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('machine.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || record.license.owner == bearer
      !record.license.protected?
    in role: Role(:license) if record.license == bearer
      !record.license.protected?
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('machine.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || record.license.owner == bearer
      !record.license.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def check_out?
    verify_permissions!('machine.check-out')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    in role: Role(:user) if record.owner == bearer || record.license.owner == bearer || bearer.machines.exists?(record.id)
      !record.license.protected?
    in role: Role(:license) if record.license == bearer
      allow!
    else
      deny!
    end
  end

  private

  def permissions_for_create
    perms = []

    perms << 'component.create' if record.components_attributes_assigned? ||
                                   record.components.any?

    perms
  end
end
