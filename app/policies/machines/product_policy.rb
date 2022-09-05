# frozen_string_literal: true

module Machines
  class ProductPolicy < ApplicationPolicy
    authorize :machine

    def show?
      verify_permissions!('machine.product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      in role: { name: 'user' } if machine.user == bearer
        allow!
      in role: { name: 'license' } if machine.license == bearer
        allow!
      else
        deny!
      end
    end
  end
end
