# frozen_string_literal: true

module Products
  class PolicyPolicy < ApplicationPolicy
    authorize :product

    def index?
      verify_permissions!('policy.read')

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
      verify_permissions!('policy.read')

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
