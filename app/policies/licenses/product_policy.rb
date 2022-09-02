# frozen_string_literal: true

module Licenses
  class ProductPolicy < ApplicationPolicy
    authorize :license

    def show?
      verify_permissions!('license.product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if license.product == bearer
        allow!
      in role: { name: 'user' } if license.user == bearer
        allow!
      in role: { name: 'license' } if license == bearer
        allow!
      else
        deny!
      end
    end
  end
end
