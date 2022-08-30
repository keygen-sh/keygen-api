# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy
  def index?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product == bearer }
      allow!
    in role: { name: 'user' } if record.all? { _1.user == bearer }
      allow!
    in role: { name: 'license' } if record.all? { _1.license == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('machine.create')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license&.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('machine.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      !record.license.protected?
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('machine.delete')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def check_out?
    verify_permissions!('machine.check-out')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end
end
