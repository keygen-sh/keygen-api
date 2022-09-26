# frozen_string_literal: true

module Machines
  class ProductPolicy < ApplicationPolicy
    authorize :machine

    def show?
      verify_permissions!('product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if machine.product == bearer
        allow!
      in role: { name: 'user' } if machine.user == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      in role: { name: 'license' } if machine.license == bearer
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      else
        deny!
      end
    end
  end
end
