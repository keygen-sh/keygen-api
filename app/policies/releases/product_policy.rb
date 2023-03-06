# frozen_string_literal: true

module Releases
  class ProductPolicy < ApplicationPolicy
    authorize :release

    def show?
      verify_permissions!('product.read')
      verify_environment!(
        strict: false,
      )

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(record.id)
        allow!
      in role: { name: 'license' } if record == bearer.product
        allow!
      else
        deny!
      end
    end
  end
end
