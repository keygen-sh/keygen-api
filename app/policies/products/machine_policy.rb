# frozen_string_literal: true

module Products
  class MachinePolicy < ApplicationPolicy
    authorize :product

    def index?
      verify_permissions!('machine.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
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
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
