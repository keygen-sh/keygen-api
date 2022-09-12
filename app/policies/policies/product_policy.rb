# frozen_string_literal: true

module Policies
  class ProductPolicy < ApplicationPolicy
    authorize :policy

    def show?
      verify_permissions!('policy.product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if policy.product == bearer
        allow!
      else
        deny!
      end
    end
  end
end
