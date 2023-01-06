# frozen_string_literal: true

class EnvironmentPolicy < ApplicationPolicy
  def index?
    verify_permissions!('environment.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('environment.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('environment.create')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('environment.update')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('environment.delete')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      deny!
    end
  end
end
