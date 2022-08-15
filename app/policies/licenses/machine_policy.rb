# frozen_string_literal: true

module Licenses
  class MachinePolicy < ApplicationPolicy
    authorize :license

    def index?
      verify_permissions!('license.machines.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allowed_to? :index?, record, with: ::MachinePolicy
      in role: { name: 'license' } if license == bearer
        allowed_to? :index?, record, with: ::MachinePolicy
      else
        deny!
      end
    end

    def show?
      verify_permissions!('license.machines.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allowed_to? :show?, record, with: ::MachinePolicy
      in role: { name: 'license' } if license == bearer
        allowed_to? :show?, record, with: ::MachinePolicy
      else
        deny!
      end
    end
  end
end
