# frozen_string_literal: true

module Products
  class ReleaseArchPolicy < ApplicationPolicy
    authorize :product

    def index?
      verify_permissions!('product.arches.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow!
      in role: { name: 'license' } if product == bearer.product
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('product.arches.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(product.id)
        allow!
      in role: { name: 'license' } if product == bearer.product
        allow!
      else
        deny!
      end
    end
  end
end
