# frozen_string_literal: true

module Releases
  class ReleaseEntitlementConstraintPolicy < ApplicationPolicy
    authorize :release

    def index?
      verify_permissions!('release.constraints.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow!
      in role: { name: 'license' } if release.product == bearer.product
        allow!
      else
        deny!
      end
    end

    def show?
      verify_permissions!('release.constraints.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      in role: { name: 'product' } if release.product == bearer
        allow!
      in role: { name: 'user' } if bearer.products.exists?(release.product.id)
        allow!
      in role: { name: 'license' } if release.product == bearer.product
        allow!
      else
        deny!
      end
    end
  end
end
