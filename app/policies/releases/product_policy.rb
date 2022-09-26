# frozen_string_literal: true

module Releases
  class ProductPolicy < ApplicationPolicy
    authorize :release

    def show?
      verify_permissions!('product.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(record.id)
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      in role: { name: 'license' } if record == bearer.product
        ENV.key?('KEYGEN_ENABLE_PERMISSIONS')
      else
        deny!
      end
    end
  end
end
