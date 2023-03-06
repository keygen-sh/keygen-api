# frozen_string_literal: true

class MachineProcessPolicy < ApplicationPolicy
  def index?
    verify_permissions!('process.read')
    verify_environment!(
      strict: false,
    )

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
    verify_permissions!('process.read')
    verify_environment!(
      strict: false,
    )

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
    verify_permissions!('process.create')
    verify_environment!

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
    verify_permissions!('process.update')
    verify_environment!

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

  def destroy?
    verify_permissions!('process.delete')
    verify_environment!

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
end
