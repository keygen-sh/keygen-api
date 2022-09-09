# frozen_string_literal: true

module Products
  class ReleasePlatformPolicy < ApplicationPolicy
    skip_pre_check :verify_authenticated!, only: %i[index? show?]

    authorize :product

    def index?
      verify_permissions!('product.platforms.read')

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
        product.open_distribution?
      end
    end

    def show?
      verify_permissions!('product.platforms.read')

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
        product.open_distribution?
      end
    end
  end
end
